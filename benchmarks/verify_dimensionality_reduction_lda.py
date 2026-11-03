#!/usr/bin/env python3
"""Check LDA projection against a grouped-covariance, hypot-normalized oracle."""
import argparse
import json
import math
from pathlib import Path
import random
import subprocess

from dimensionality_reduction_lda_oracle import expected_result


def corpus():
    workload = json.loads((Path(__file__).parent / 'd/dimensionality_reduction_lda/workload.json').read_text())
    rows = []

    def add(values, capacity=8, null_input=False, null_output=False):
        result = None if null_input else expected_result(values)
        status = -1 if result is None else (-2 if null_output or capacity < len(result) else len(result))
        output = result if status >= 0 else []
        rows.append(f'{len(values)} {status} {len(output)} {capacity} {int(null_input)} {int(null_output)}\n'
                    + ' '.join(format(x, '.17g') for x in values) + '\n'
                    + ' '.join(format(x, '.17g') for x in output) + '\n')
        return status, output

    for case in workload['cases']:
        status, output = add(case['input_values'], case.get('output_capacity', 8))
        if status != case['expected_result'] or len(output) != len(case['expected_output']):
            raise ValueError(f"fixture disagrees with oracle: {case['id']}")
        for a, b in zip(output, case['expected_output']):
            if abs(a-b) > 1e-10 + 1e-10*abs(b):
                raise ValueError(f"fixture disagrees with oracle: {case['id']}")
    # Positive determinant just above the accepted boundary, with strongly
    # anisotropic within-class variance. A fixed Newton iteration count from
    # norm-squared is insufficient for this valid projection direction.
    for epsilon in (3e-10, 1e-9, 1e-8):
        add([2, 4, 2, 1, -10000, 10000, 0, 0,
             0, 0, 4-epsilon, 4+epsilon, 0, 0, 1, 1])
    rng = random.Random(741903)
    for n in range(4, 9):
        for trial in range(160):
            scale = (0.001, 0.1, 1, 100, 1000)[trial % 5]
            labels = [0, 0, 1, 1] + [rng.randrange(2) for _ in range(n-4)]
            rng.shuffle(labels)
            values = [2, n, 2, 1, *[rng.randrange(-8, 9)*scale for _ in range(2*n)], *labels]
            for capacity in (0, n-1, n, n+1):
                add(values, capacity)
            add(values, n, null_input=True)
            add(values, n, null_output=True)
    valid = [2, 4, 2, 1, 0, 2, 3, 5, 0, 0, 2, 4, 0, 0, 1, 1]
    for length in range(30):
        add((valid+[0]*30)[:length])
    for slot in range(len(valid)):
        for value in (math.nan, math.inf, -math.inf, -1e300, 1e300):
            values = valid.copy(); values[slot] = value
            add(values)
    for count in (-1, 0, 3, 4.5, 5, 6, 7, 8, 8.5, 9):
        values = valid.copy(); values[1] = count
        add(values)
    for axis in (0, 1):
        for edge in (-10000.00001, -10000, 10000, 10000.00001):
            values=valid.copy(); values[4+4*axis]=edge
            add(values)
    return f'{len(rows)} 1e-10 1e-10 10\n'+''.join(rows), len(rows)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--checker', action='append', required=True)
    args = parser.parse_args()
    data, count = corpus()
    for checker in args.checker:
        result = subprocess.run([checker], input=data, capture_output=True, text=True, timeout=25)
        if result.returncode:
            raise RuntimeError(f'{checker}: {result.stderr}')
        observed = json.loads(result.stdout)
        if observed['cases_checked'] != count:
            raise RuntimeError(f'incomplete corpus: {observed}')
        print(json.dumps({'checker': checker, 'cases_checked': count}))


if __name__ == '__main__':
    main()
