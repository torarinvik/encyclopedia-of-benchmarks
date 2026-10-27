"""Independent Prim-plus-pairing verifier for Christofides' bounded profile."""

from __future__ import annotations

import struct
from collections.abc import Sequence

MAX_INPUT = 65
MAX_OUTPUT_BYTES = 80


def _valid(values):
    if (not isinstance(values, (list, tuple)) or len(values) < 2 or len(values) > MAX_INPUT
            or any(type(x) is not int or not -(1 << 63) <= x < (1 << 63) for x in values)):
        return None
    n = values[0]
    if not 1 <= n <= 8 or len(values) != 1 + n * n:
        return None
    d = [values[1 + i * n:1 + (i + 1) * n] for i in range(n)]
    if (any(not 0 <= d[i][j] <= 10000 for i in range(n) for j in range(n))
            or any(d[i][i] != 0 for i in range(n))
            or any(d[i][j] != d[j][i] for i in range(n) for j in range(n))
            or any(d[i][j] > d[i][k] + d[k][j]
                   for i in range(n) for j in range(n) for k in range(n))):
        return None
    return n, d


def _minimum_matching(odd, d):
    best_cost = None
    best_pairs = None

    def visit(remaining, pairs, cost):
        nonlocal best_cost, best_pairs
        if not remaining:
            canonical = tuple(pairs)
            if best_cost is None or cost < best_cost or (cost == best_cost and canonical < best_pairs):
                best_cost, best_pairs = cost, canonical
            return
        a = remaining[0]
        for j in range(1, len(remaining)):
            b = remaining[j]
            visit(remaining[1:j] + remaining[j + 1:], pairs + [(a, b)], cost + d[a][b])

    visit(list(odd), [], 0)
    return best_pairs or ()


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or capacity is not None and (type(capacity) is not int or capacity < 0)
            or input_length is not None and (type(input_length) is not int or not 0 <= input_length <= MAX_INPUT)
            or input_is_null and values not in (None, [], ())
            or not input_is_null and values is not None and input_length is not None
            and input_length != len(values)):
        return -1, b""
    if input_is_null or values is None:
        return -1, b""
    parsed = _valid(values)
    if parsed is None:
        return -1, b""
    n, d = parsed

    # Kruskal uses the contract's canonical order independently of the primary
    # oracle's subset-DP matching reconstruction.
    parent = list(range(n))

    def find(x):
        while parent[x] != x:
            x = parent[x]
        return x

    tree = [[0] * n for _ in range(n)]
    edges = sorted((d[u][v], u, v) for u in range(n) for v in range(u + 1, n))
    picked = 0
    for _, u, v in edges:
        a, b = find(u), find(v)
        if a != b:
            parent[b] = a
            tree[u][v] = tree[v][u] = 1
            picked += 1
            if picked == n - 1:
                break
    odds = [v for v in range(n) if sum(tree[v]) % 2]
    for u, v in _minimum_matching(odds, d):
        tree[u][v] += 1
        tree[v][u] += 1

    # Independent multigraph traversal: consume the least available neighbor.
    remaining = [row[:] for row in tree]
    walk = [0]
    closed = []
    while walk:
        v = walk[-1]
        choices = [w for w in range(n) if remaining[v][w] > 0]
        if choices:
            w = choices[0]
            remaining[v][w] -= 1
            remaining[w][v] -= 1
            walk.append(w)
        else:
            closed.append(walk.pop())
    order = list(dict.fromkeys(reversed(closed)))
    tour = [*order, 0]
    cost = sum(d[tour[i]][tour[i + 1]] for i in range(n))
    output = b"".join(struct.pack("<q", x) for x in (cost, *tour))
    if output_is_null or capacity is not None and capacity < len(output):
        return -2, b""
    return len(output), output
