import atexit
import argparse
import codecs
import multiprocessing
import os
import psutil
import select
import subprocess


_FSWATCH_BIN = (
    '@fswatch@'
    '/bin/fswatch'
)


def _command_process(args, stdout_pipe_in, stderr_pipe_in, quit_pipe_out):
    os.setsid()
    popen = subprocess.Popen(
        args,
        stdin=subprocess.DEVNULL,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
    )
    open_input_streams = [quit_pipe_out, popen.stdout, popen.stderr]
    while open_input_streams:
        selected, _, _ = select.select(open_input_streams, [], [])
        if popen.stdout in selected:
            value = popen.stdout.read1()
            if value:
                stdout_pipe_in.send_bytes(value)
            else:
                open_input_streams.remove(popen.stdout)
                stdout_pipe_in.close()
        if popen.stderr in selected:
            value = popen.stderr.read1()
            if value:
                stderr_pipe_in.send_bytes(value)
            else:
                open_input_streams.remove(popen.stderr)
                stderr_pipe_in.close()
        if quit_pipe_out in selected:
            quit_pipe_out.recv()
            open_input_streams.remove(quit_pipe_out)
            quit_pipe_out.close()
            _kill_session()
    popen.wait()
    while _kill_session():
        pass


def _kill_session():
    """
    returns:
        True iff at least one process was terminated
    """
    pid = os.getpid()
    sid = os.getsid(pid)
    psutil.process_iter.cache_clear()
    session_procs = [
        candidate_proc
        for candidate_proc in psutil.process_iter()
        if os.getsid(candidate_proc.pid) == sid
        and candidate_proc.pid != pid
    ]
    if not session_procs:
        return False
    for session_proc in session_procs:
        session_proc.terminate()
    psutil.wait_procs(session_procs)
    return True


class Outputter:
    def __init__(self):
        self.last_source = None
        self.incomplete_line = False

    def output(self, source, text):
        if source != self.last_source:
            if self.incomplete_line:
                print()
            if self.last_source is not None:
                print(f'^^^ {self.last_source} ^^^')
            print(f'vvv {source} vvv')
        print(text, end='')
        self.last_source = source
        self.incomplete_line = not text.endswith("\n")


def _main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--paths', nargs='*', dest='paths', default=[])
    parser.add_argument('command', nargs='+')
    args = parser.parse_args()
    outputter = Outputter()
    fswatch = subprocess.Popen(
        [
            _FSWATCH_BIN,
            '--event',
            'Created',
            '--event',
            'Updated',
            '--event',
            'Removed',
            '--recursive',
            *args.paths
        ],
        stdin=subprocess.DEVNULL,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
    )
    fswatch_stdout_decoder = codecs.getincrementaldecoder('utf-8')()
    fswatch_stdout_buffer = ''
    fswatch_stderr_decoder = codecs.getincrementaldecoder('utf-8')()
    while True:
        stdout_pipe_out, stdout_pipe_in = multiprocessing.Pipe(False)
        stderr_pipe_out, stderr_pipe_in = multiprocessing.Pipe(False)
        quit_pipe_out, quit_pipe_in = multiprocessing.Pipe(False)
        command_stdout_decoder = codecs.getincrementaldecoder('utf-8')()
        command_stderr_decoder = codecs.getincrementaldecoder('utf-8')()

        def cleanup():
            quit_pipe_in.send(None)

        def output_passthrough_streams(selected):
            if fswatch.stderr in selected:
                outputter.output(
                    'error',
                    fswatch_stderr_decoder.decode(fswatch.stderr.read1()),
                )
            if stdout_pipe_out in selected:
                outputter.output(
                    'command stdout',
                    command_stdout_decoder.decode(
                        stdout_pipe_out.recv_bytes(),
                    ),
                )
            if stderr_pipe_out in selected:
                outputter.output(
                    'command stderr',
                    command_stderr_decoder.decode(
                        stderr_pipe_out.recv_bytes(),
                    ),
                )

        atexit.register(cleanup)
        command = multiprocessing.Process(
            target=_command_process,
            args=(args.command, stdout_pipe_in, stderr_pipe_in, quit_pipe_out),
        )
        command.start()
        while True:
            selected, _, _ = select.select(
                [
                    fswatch.stdout,
                    fswatch.stderr,
                    stdout_pipe_out,
                    stderr_pipe_out,
                ],
                [],
                [],
            )
            output_passthrough_streams(selected)
            if fswatch.stdout in selected:
                outputter.output('watch', "Stopping.\n")
                quit_pipe_in.send(None)
                atexit.unregister(cleanup)
                modified = set()
                while True:
                    selected, _, _ = select.select(
                        [
                            command.sentinel,
                            fswatch.stdout,
                            fswatch.stderr,
                            stdout_pipe_out,
                            stderr_pipe_out,
                        ],
                        [],
                        [],
                    )
                    output_passthrough_streams(selected)
                    if fswatch.stdout in selected:
                        fswatch_stdout_buffer += fswatch_stdout_decoder.decode(
                            fswatch.stdout.read1()
                        )
                        while True:
                            split = fswatch_stdout_buffer.split("\n", 1)
                            if len(split) > 1:
                                modified.add(split[0])
                                fswatch_stdout_buffer = split[1]
                            else:
                                fswatch_stdout_buffer = split[0]
                                break
                    if command.sentinel in selected:
                        command.close()
                        quit_pipe_in.close()
                        message = "Modified:\n"
                        for file in sorted(modified):
                            message += "    " + file + "\n"
                        message += "Restarting."
                        outputter.output('watch', message)
                        break
                break


if __name__ == '__main__':
    _main()
