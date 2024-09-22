#! @python3@/bin/python

import argparse
import os
import queue
import signal
import subprocess
import sys
import threading

def _process_output(out, callback):
    for line in out:
        callback(line)

def _enqueue_changed_file(q):
    def callback(line):
        q.put(''.join(line.decode("utf-8").splitlines()))
    return callback

def _enqueue_line_with_metadata(q, metadata):
    def callback(line):
        for split in line.decode("utf-8").splitlines():
            q.put((metadata, split))
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
        print(line)

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

def _main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--paths', nargs='*', dest='paths', default=[])
    parser.add_argument('command', nargs='+')
    args = parser.parse_args()
    fswatch_queue = queue.Queue()
    output_queue = queue.Queue()
    _start_output_merge_thread(output_queue)
    if args.paths:
        fswatch = subprocess.Popen(['@fswatch@/bin/fswatch', '--recursive', '--event', 'Created', '--event', 'Updated', '--event', 'Removed', *args.paths], stdout=subprocess.PIPE)
        _start_output_thread(fswatch.stdout, _enqueue_changed_file(fswatch_queue))
    while True:
        command = None
        try:
            command = subprocess.Popen([*args.command], stdin=subprocess.DEVNULL, stdout=subprocess.PIPE, stderr=subprocess.PIPE, start_new_session=True)
            command_thread_stdout = _start_output_thread(command.stdout, _enqueue_line_with_metadata(output_queue, 'command'))
            command_thread_stderr = _start_output_thread(command.stderr, _enqueue_line_with_metadata(output_queue, 'command'))
            modified = set()
            modified.add(fswatch_queue.get())
            output_queue.put(('watch', 'Stopping.'))
            os.killpg(os.getpgid(command.pid), signal.SIGTERM)
            command.wait()
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
                os.killpg(os.getpgid(command.pid), signal.SIGTERM)
            raise

if __name__ == '__main__':
    _main()
