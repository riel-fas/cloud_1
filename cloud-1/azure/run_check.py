#!/usr/bin/env python3
"""Run a read-only preflight command with progress and a bounded wait."""
import argparse
import os
import signal
import subprocess
import sys
import time


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--timeout', type=float, default=120)
    parser.add_argument('--interval', type=float, default=15)
    parser.add_argument('command', nargs=argparse.REMAINDER)
    args = parser.parse_args()
    if not args.command or args.timeout <= 0 or args.interval <= 0:
        parser.error('Provide a command and positive timeout/interval')
    process = subprocess.Popen(args.command, start_new_session=True)
    start = time.monotonic()
    try:
        while True:
            status = process.poll()
            if status is not None:
                return status
            remaining = args.timeout - (time.monotonic() - start)
            if remaining <= 0:
                print('Check timed out. Azure response remains unverified; deployment stopped.', file=sys.stderr)
                return 124
            try:
                return process.wait(timeout=min(args.interval, remaining))
            except subprocess.TimeoutExpired:
                elapsed = int(time.monotonic() - start)
                print(f'  Still waiting for Azure ({elapsed}s elapsed; limit {args.timeout:g}s)...', file=sys.stderr, flush=True)
    except KeyboardInterrupt:
        print('\nCheck cancelled.', file=sys.stderr)
        return 130
    finally:
        if process.poll() is None:
            os.killpg(process.pid, signal.SIGTERM)
            try:
                process.wait(timeout=3)
            except subprocess.TimeoutExpired:
                os.killpg(process.pid, signal.SIGKILL)
                process.wait()


if __name__ == '__main__':
    sys.exit(main())
