#!/usr/bin/env python3
"""Verify exact cycle enumeration, errors, output bounds, and input preservation."""
import argparse
import ctypes
import itertools
import json
from pathlib import Path
import random

from directed_simple_cycles_oracle import expected_output


def permutation_output(values):
    if values is None or len(values) < 2:
        return -1, b''
    n, m = values[:2]
    if not 0 <= n <= 6 or not 0 <= m <= 36 or len(values) != 2 + 2 * m:
        return -1, b''
    arcs = set(zip(values[2::2], values[3::2]))
    if any(not 0 <= u < n or not 0 <= v < n for u, v in arcs):
        return -1, b''
    cycles = []
    for count in range(1, n + 1):
        for path in itertools.permutations(range(n), count):
            if path[0] != min(path):
                continue
            if all((path[i], path[(i + 1) % count]) in arcs for i in range(count)):
                cycles.append(path)
    raw = b''.join(bytes((*path, path[0], 255)) for path in sorted(cycles))
    return len(raw), raw


def corpus():
    workload = Path(__file__).parent / 'd/directed_simple_cycles/workload.json'
    for case in json.loads(workload.read_text())['cases']:
        result, raw = expected_output(case['input_values'])
        if result > case['workspace_bytes'] and result > 0:
            result, raw = -2, b''
        assert (result, raw) == (case['expected_result'], bytes.fromhex(case['expected_output_hex']))
        yield case['input_values']
    for n in range(4):
        edges = list(itertools.product(range(n), repeat=2))
        for mask in range(1 << len(edges)):
            selected = [edge for i, edge in enumerate(edges) if mask & (1 << i)]
            yield [n, len(selected), *(v for edge in selected for v in edge)]
    rng = random.Random(13201)
    for _ in range(1000):
        n = rng.randrange(1, 7)
        m = rng.randrange(37)
        yield [n, m, *(rng.randrange(n) for _ in range(2 * m))]
    yield None
    for values in [[], [0], [0, 1, 0, 0], [-1, 0], [7, 0], [1, -1], [1, 37, *([0] * 74)],
                   [1, 1, -1, 0], [1, 1, 0, 1], [1, 1, 0], [1, 0, 0, 0]]:
        yield values


def check(library, cases):
    lib = ctypes.CDLL(str(Path(library).resolve()))
    fn = lib.directed_simple_cycles
    fn.argtypes = [ctypes.POINTER(ctypes.c_int64), ctypes.c_size_t,
                   ctypes.POINTER(ctypes.c_uint8), ctypes.c_size_t]
    fn.restype = ctypes.c_int64
    size = 2786 + 32
    untouched = bytes([0xA5]) * size
    buffer = (ctypes.c_uint8 * size)()
    count = 0
    for values, (result, raw) in cases:
        data = None if values is None else (ctypes.c_int64 * max(1, len(values)))(*values)
        length = 2 if values is None else len(values)
        for capacity in sorted({0, max(0, len(raw) - 1), len(raw), 2786}):
            for null_output in (False, True):
                expected = result
                written = raw
                if result > 0 and (null_output or capacity < len(raw)):
                    expected, written = -2, b''
                ctypes.memset(buffer, 0xA5, size)
                out = None if null_output else ctypes.cast(ctypes.byref(buffer, 16), ctypes.POINTER(ctypes.c_uint8))
                actual = fn(data, length, out, capacity)
                assert actual == expected, (library, values, capacity, null_output, actual, expected)
                reference = untouched[:16] + written + untouched[16 + len(written):]
                assert bytes(buffer) == reference, 'output mismatch or out-of-range write'
                if values is not None:
                    assert list(data)[:len(values)] == values, 'input mutated'
                count += 1
    print(f'{library}: passed {count} cases')


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('libraries', nargs='+', type=Path)
    args = parser.parse_args()
    cases = []
    for values in corpus():
        reference = expected_output(values)
        assert reference == permutation_output(values), f'oracles disagree: {values}'
        cases.append((values, reference))
    for library in args.libraries:
        check(library, cases)


if __name__ == '__main__':
    main()
