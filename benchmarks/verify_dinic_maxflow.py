#!/usr/bin/env python3
"""Compare Dinic implementations with an independent bounded max-flow oracle."""
import argparse
import json
from pathlib import Path
import random
import subprocess

from dinic_maxflow_oracle import expected_result


def corpus():
    workload = json.loads((Path(__file__).parent / 'd/dinic_maxflow/workload.json').read_text())
    cases = []
    for case in workload['cases']:
        values = case['input_values']
        if expected_result(values) != case['expected_result']:
            raise ValueError('workload disagrees with oracle: ' + case['id'])
        cases.append(values)
    rng = random.Random(72149)
    for _ in range(3000):
        n = rng.randint(2, 16)
        m = rng.randint(0, 64)
        source, sink = rng.sample(range(1, n + 1), 2)
        values = [n, m, source, sink]
        for _ in range(m):
            u, v = rng.sample(range(1, n + 1), 2)
            values.extend((u, v, rng.randrange(101)))
        if rng.random() < .20:
            if m and rng.random() < .5:
                values[4 + 3 * rng.randrange(m)] = n + 1
            else:
                values.append(123)
        cases.append(values)
    rows = [f"{len(a)} {expected_result(a)} " + ' '.join(map(str, a)) + '\n' for a in cases]
    return f'{len(rows)}\n' + ''.join(rows), len(rows)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--checker', action='append', required=True)
    args = parser.parse_args()
    data, count = corpus()
    for checker in args.checker:
        result = subprocess.run([checker], input=data, capture_output=True, text=True, timeout=25)
        if result.returncode:
            raise RuntimeError(checker + ': ' + result.stderr)
        if json.loads(result.stdout)['cases_checked'] != count:
            raise RuntimeError(checker + ': incomplete corpus')
        print(json.dumps({'checker': checker, 'cases_checked': count}))


if __name__ == '__main__':
    main()
