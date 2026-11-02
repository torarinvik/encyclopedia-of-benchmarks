#!/usr/bin/env python3
"""Check the bounded Dijkstra ports using exhaustive graphs and Floyd-Warshall."""
import argparse
import itertools
import json
from pathlib import Path
import struct
import subprocess


def oracle(values):
    if len(values) < 2:
        return None
    n, m = values[:2]
    if not 2 <= n <= 4 or not n - 1 <= m <= n * (n - 1) // 2 or len(values) != 2 + 3 * m:
        return None
    distances = [[None] * n for _ in range(n)]
    for i in range(n):
        distances[i][i] = 0
    for i in range(m):
        u, v, weight = values[2 + 3 * i:5 + 3 * i]
        if not 0 <= u < n or not 0 <= v < n or u == v or not 1 <= weight <= 255:
            return None
        if distances[u][v] is not None:
            return None
        distances[u][v] = distances[v][u] = weight
    for k in range(n):
        for i in range(n):
            for j in range(n):
                if distances[i][k] is not None and distances[k][j] is not None:
                    via = distances[i][k] + distances[k][j]
                    if distances[i][j] is None or via < distances[i][j]:
                        distances[i][j] = via
    if any(value is None for value in distances[0]):
        return None
    return b"".join(struct.pack("<q", value) for value in distances[0])


def corpus():
    rows = []

    def add(values, capacity=64, null_input=False, null_output=False):
        output = None if null_input else oracle(values)
        result = -1 if output is None else (-2 if null_output or len(output) > capacity else len(output))
        expected = output if result >= 0 else b""
        rows.append(f"{len(values)} {result} {len(expected)} {capacity} {int(null_input)} {int(null_output)}\n"
                    + " ".join(map(str, values)) + "\n" + (expected.hex() or "-") + "\n")

    workload = json.loads((Path(__file__).parent / "d/dijkstra_positive_connected/workload.json").read_text())
    for case in workload["cases"]:
        values = case["input_values"]
        output = oracle(values)
        result = -1 if output is None else len(output)
        encoded = "" if output is None else output.hex()
        if (case["input_length"] != len(values) or case["expected_result"] != result
                or case["expected_output_hex"] != encoded):
            raise ValueError(f"published workload disagrees with independent oracle: {case['id']}")
        add(values)

    for n in range(2, 5):
        pairs = list(itertools.combinations(range(n), 2))
        for weights in itertools.product((0, 1, 2, 255), repeat=len(pairs)):
            edges = [(u, v, w) for (u, v), w in zip(pairs, weights) if w]
            values = [n, len(edges)] + [part for edge in edges for part in edge]
            add(values)
            if oracle(values) is not None:
                for capacity in (0, n * 8 - 1, n * 8):
                    add(values, capacity)
                add(values, null_output=True)
                # Edge order and orientation must not affect undirected distances.
                add([n, len(edges)] + [part for u, v, w in reversed(edges) for part in (v, u, w)])
    invalid = [[], [0, 0], [1, 0], [-1, 0], [5, 0], [2, -1], [2, 7],
               [2, 1], [2, 1, 0, 1, 1, 0], [2, 1, 0, 0, 1],
               [3, 2, 0, 1, 1, 1, 0, 2], [4, 3, 0, 1, 1, 0, 1, 2, 2, 3, 1]]
    for endpoint in (-2**63, -1, 2, 2**63 - 1):
        invalid.extend(([2, 1, endpoint, 1, 1], [2, 1, 0, endpoint, 1]))
    for weight in (-2**63, -1, 0, 256, 2**63 - 1):
        invalid.append([2, 1, 0, 1, weight])
    for values in invalid:
        add(values)
        add(values, null_output=True)
    for values in ([], [2], [2, 1, 0, 1, 1], [4, 0]):
        add(values, null_input=True)
    return str(len(rows)) + "\n" + "".join(rows), len(rows)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--checker", action="append", required=True)
    args = parser.parse_args()
    data, count = corpus()
    for checker in args.checker:
        result = subprocess.run([checker], input=data, text=True, capture_output=True, timeout=12, check=True)
        observed = json.loads(result.stdout)
        if observed.get("cases_checked") != count:
            raise RuntimeError(f"checker did not consume the complete corpus: {checker}")
        print(json.dumps({"checker": checker, "cases_checked": count}))


if __name__ == "__main__":
    main()
