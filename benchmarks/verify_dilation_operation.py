#!/usr/bin/env python3
"""Validate binary dilation by propagating foreground coordinates through the kernel."""
import argparse
import itertools
import json
from pathlib import Path
import random
import struct
import subprocess


def oracle(values):
    if not 12 <= len(values) <= 267:
        return None
    rows, columns = values[:2]
    if not 1 <= rows <= 16 or not 1 <= columns <= 16 or len(values) != rows * columns + 11:
        return None
    if any(value not in (0, 1) for value in values[2:]):
        return None
    foreground = {divmod(i, columns) for i, value in enumerate(values[2:2 + rows * columns]) if value}
    kernel = {divmod(i, 3) for i, value in enumerate(values[2 + rows * columns:]) if value}
    active = {(y + 1 - ky, x + 1 - kx) for y, x in foreground for ky, kx in kernel}
    return b''.join(struct.pack('<i', int((y, x) in active)) for y in range(rows) for x in range(columns))


def corpus():
    records = []

    def add(values, capacity=1024, null_input=False, null_output=False):
        output = None if null_input else oracle(values)
        result = -1 if output is None else (-2 if null_output or len(output) > capacity else len(output) // 4)
        encoded = output if result >= 0 else b''
        records.append(f'{len(values)} {result} {len(encoded)} {capacity} {int(null_input)} {int(null_output)}\n'
                       + ' '.join(map(str, values)) + '\n' + (encoded.hex() or '-') + '\n')
        return result, encoded.hex()

    workload = json.loads((Path(__file__).parent / 'd/dilation_operation/workload.json').read_text())
    for case in workload['cases']:
        result, encoded = add(case['input_values'], case.get('workspace_bytes', 1024))
        if (len(case['input_values']) != case['input_length'] or result != case['expected_result']
                or encoded != case['expected_output_hex']):
            raise ValueError(f"fixture disagrees with independent oracle: {case['id']}")
    for rows, columns in itertools.product((1, 2), repeat=2):
        for image in itertools.product((0, 1), repeat=rows * columns):
            for kernel in itertools.product((0, 1), repeat=9):
                add([rows, columns, *image, *kernel])
    rng = random.Random(359103)
    for rows, columns in itertools.product(range(1, 17), repeat=2):
        for image in ([0] * (rows * columns), [rng.randrange(2) for _ in range(rows * columns)]):
            for mask in (0, 1, 16, 511):
                add([rows, columns, *image, *((mask >> bit) & 1 for bit in range(9))])
        valid = [rows, columns, *([1] * (rows * columns)), *([1] * 9)]
        add(valid, rows * columns * 4)
        add(valid, rows * columns * 4 - 1)
        add(valid, null_output=True)
    valid = [1, 1, 1, *([1] * 9)]
    for dimension in (-2**63, -1, 0, 17, 2**63 - 1):
        for slot in (0, 1):
            invalid = valid.copy(); invalid[slot] = dimension
            add(invalid)
    for value in (-2**63, -1, 2, 2**63 - 1):
        for slot in range(2, len(valid)):
            invalid = valid.copy(); invalid[slot] = value
            add(invalid)
            add(invalid, null_output=True)
    for values in ([], [1], valid[:-1], valid + [0], [16, 16, *([0] * 265), 0]):
        add(values)
        add(values, null_input=True)
    for values in (valid, [16, 16, *([1] * 265)]):
        add(values, null_input=True)
    return str(len(records)) + '\n' + ''.join(records), len(records)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--checker', action='append', required=True)
    args = parser.parse_args()
    data, count = corpus()
    for checker in args.checker:
        result = subprocess.run([checker], input=data, text=True, capture_output=True, timeout=15)
        if result.returncode:
            raise RuntimeError(f'{checker}: {result.stderr}')
        if json.loads(result.stdout).get('cases_checked') != count:
            raise ValueError('checker did not consume complete corpus')
        print(json.dumps({'checker': checker, 'cases_checked': count}))


if __name__ == '__main__':
    main()
