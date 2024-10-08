import argparse
import codecs
import os
import psutil
import queue
import subprocess
import threading


_FSWATCH_BIN = (
    '@fswatch@'
    '/bin/fswatch'
)


def _process_output(out, callback):
    for line in codecs.iterdecode(out, 'utf-8'):
        callback(line)


def _enqueue_changed_file(q):
    def callback(line):
        q.put(line)
    return callback


def _enqueue_line_with_metadata(q, metadata):
    def callback(line):
        q.put((metadata, line))
    return callback


def _merge_output(q):
    last_name = None
    while True:
        ((name), line) = q.get()
        if last_name != name:
            if last_name is not None:
                print(f'^^^ {last_name} ^^^')
            print(f'vvv {name} vvv')
            last_name = name
        print(line.rstrip('\n'))


def _start_output_thread(out, callback):
    thread = threading.Thread(target=_process_output, args=(out, callback))
    thread.daemon = True
    thread.start()
    return thread


def _start_output_merge_thread(q):
    thread = threading.Thread(target=_merge_output, args=(q,))
    thread.daemon = True
    thread.start()
    return thread


def _kill_session(proc):
    proc.terminate()
    sid = os.getsid(proc.pid)
    while True:
        psutil.process_iter.cache_clear()
        session_procs = [
            candidate_proc
            for candidate_proc in psutil.process_iter()
            if os.getsid(candidate_proc.pid) == sid
            and candidate_proc.pid != proc.pid
        ]
        if not session_procs:
            break
        for session_proc in session_procs:
            session_proc.terminate()
        psutil.wait_procs(session_procs)
    proc.wait()


def _main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--paths', nargs='*', dest='paths', default=[])
    parser.add_argument('command', nargs='+')
    args = parser.parse_args()
    fswatch_queue = queue.Queue()
    output_queue = queue.Queue()
    _start_output_merge_thread(output_queue)
    if args.paths:
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
            stderr=subprocess.DEVNULL
        )
        _start_output_thread(
            fswatch.stdout,
            _enqueue_changed_file(fswatch_queue)
        )
    while True:
        command = None
        try:
            command = subprocess.Popen(
                [*args.command],
                stdin=subprocess.DEVNULL,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                start_new_session=True
            )
            command_thread_stdout = _start_output_thread(
                command.stdout,
                _enqueue_line_with_metadata(output_queue, 'command')
            )
            command_thread_stderr = _start_output_thread(
                command.stderr,
                _enqueue_line_with_metadata(output_queue, 'command')
            )
            modified = set()
            modified.add(fswatch_queue.get())
            output_queue.put(('watch', 'Stopping.'))
            _kill_session(command)
            command_thread_stdout.join()
            command_thread_stderr.join()
            while not fswatch_queue.empty():
                modified.add(fswatch_queue.get())
            message = "Modified:\n"
            for file in sorted(modified):
                message += "    " + file + "\n"
            message += "Restarting."
            output_queue.put(('watch', message))
        except KeyboardInterrupt:
            if command is not None:
                _kill_session(command)
            raise


if __name__ == '__main__':
    _main()
