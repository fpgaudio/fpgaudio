#!/usr/bin/env python

import argparse
from serial import Serial
from time import sleep


def float_to_fixed(x: float) -> int:
    return int(round(x * (1 << 16)))


def create_byte_stream(*args: float) -> bytes:
    return b''.join(float_to_fixed(val).to_bytes(4)
                    for val in args)


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument('serial_dev')
    args = parser.parse_args()

    palm_distance = 0
    with Serial(args.serial_dev) as dev:
        while True:
            data_to_write = [palm_distance, 0, 0, 0, 0]
            dev.write(create_byte_stream(*data_to_write))
            sleep(1)
            palm_distance += 1


if __name__ == '__main__':
    main()
