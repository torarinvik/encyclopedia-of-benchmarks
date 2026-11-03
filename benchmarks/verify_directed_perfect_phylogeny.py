#!/usr/bin/env python3
"""Verify native implementations against independent set and bit-mask oracles."""
import argparse
import ctypes
import itertools
from pathlib import Path
import random

from directed_perfect_phylogeny_oracle import evaluate
from directed_perfect_phylogeny_verifier_oracle import verify


def corpus():
    for n, m in [(1, 1), (2, 2), (3, 3)]:
        for bits in itertools.product((0, 1), repeat=n * m):
            yield [n, m, *bits]
    rng = random.Random(41989)
    for n in range(1, 13):
        for m in range(1, 13):
            for pattern in range(8):
                bits = [0 if pattern == 0 else 1 if pattern == 1 else rng.randrange(2)
                        for _ in range(n * m)]
                yield [n, m, *bits]
    yield None
    for values in [[], [1], [1, 1], [0, 1, 0], [1, 0, 0], [13, 1, *([0] * 13)],
                   [1, 13, *([0] * 13)], [1, 1, -1], [1, 1, 2], [1, 1, 0, 0],
                   [12, 12, *([0] * 143)], [12, 12, *([0] * 145)]]:
        yield values


def check(library):
    lib = ctypes.CDLL(str(Path(library).resolve()))
    fn = lib.directed_perfect_phylogeny
    fn.argtypes = [ctypes.POINTER(ctypes.c_int64), ctypes.c_size_t,
                   ctypes.POINTER(ctypes.c_uint8), ctypes.c_size_t]
    fn.restype = ctypes.c_int64
    count = 0
    for values in corpus():
        reference = evaluate(values)
        assert reference == verify(values), f'oracles disagree: {values}'
        data = None if values is None else (ctypes.c_int64 * max(1, len(values)))(*values)
        length = 1 if values is None else len(values)
        for capacity in (0, 7, 8, 16):
            for null_output in (False, True):
                buffer = (ctypes.c_uint8 * 32)(*([0xA5] * 32))
                out = None if null_output else ctypes.cast(ctypes.byref(buffer, 8), ctypes.POINTER(ctypes.c_uint8))
                expected, raw = reference
                if expected == 8 and (null_output or capacity < 8):
                    expected, raw = -2, b''
                result = fn(data, length, out, capacity)
                assert result == expected, (values, capacity, null_output, result, expected)
                expected_buffer = bytearray([0xA5] * 32)
                if raw:
                    expected_buffer[8:16] = raw
                assert bytes(buffer) == bytes(expected_buffer), 'output or canary mismatch'
                if values is not None:
                    assert list(data)[:len(values)] == values, 'input mutated'
                count += 1
    print(f'{library}: passed {count} cases')


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('libraries', nargs='+', type=Path)
    for library in parser.parse_args().libraries:
        check(library)


if __name__ == '__main__':
    main()
