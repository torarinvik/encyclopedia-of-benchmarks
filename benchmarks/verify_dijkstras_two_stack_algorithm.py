#!/usr/bin/env python3
"""Check two-stack implementations against the recursive-descent oracle."""
import argparse
import itertools
import json
from pathlib import Path
import random
import subprocess

from dijkstras_two_stack_algorithm_oracle import INVALID_RESULT, expected_result


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--checker', action='append', required=True)
    args = parser.parse_args()
    root = Path(__file__).resolve().parents[1]
    workload = json.loads((root / 'benchmarks/d/dijkstras_two_stack_algorithm/workload.json').read_text())
    cases = {}
    for case in workload['cases']:
        values = tuple(case['input_values'])
        result = expected_result(values)
        if result != case['expected_result'] or len(values) != case['input_length']:
            raise ValueError(f"incorrect fixture: {case['id']}")
        cases[values] = result
    for digit in range(10):
        cases[(48 + digit,)] = digit
    for left, right, op in itertools.product(range(10), range(10), '+-*/'):
        values = tuple(map(ord, f'({left}{op}{right})'))
        cases[values] = expected_result(values)
    rng = random.Random(839172)

    def expression(depth):
        if depth == 0 or rng.randrange(4) == 0:
            return str(rng.randrange(10))
        return f'({expression(depth-1)}{rng.choice("+-*/")}{expression(depth-1)})'

    for _ in range(3000):
        values = tuple(map(ord, expression(rng.randrange(1, 8))))
        if len(values) <= 511:
            cases[values] = expected_result(values)
    for values in [(), (48,) * 512, (127,), (-1,), (1 << 62,)]:
        cases[values] = INVALID_RESULT
    records = [f'{len(v)} {r} ' + ' '.join(map(str, v)) + '\n' for v, r in cases.items()]
    records.extend(f'NULL {n} {INVALID_RESULT}\n' for n in (0, 1, 511, 512))
    payload = str(len(records)) + '\n' + ''.join(records)
    for checker in args.checker:
        result = subprocess.run([checker], input=payload, text=True, capture_output=True, timeout=20)
        if result.returncode:
            raise RuntimeError(f'{checker}: {result.stderr}')
        reported = json.loads(result.stdout)
        if reported['cases_checked'] != len(records):
            raise ValueError('checker skipped cases')
        print(json.dumps({'checker': checker, **reported}))


if __name__ == '__main__':
    main()
