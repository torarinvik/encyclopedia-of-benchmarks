"""Primary deterministic Christofides-profile oracle for a bounded metric."""

from __future__ import annotations

import struct
from collections.abc import Sequence

MAX_N = 8
MAX_INPUT = 65
MAX_OUTPUT_BYTES = 80


def _parse(values: Sequence[int] | None):
    if (not isinstance(values, (list, tuple)) or len(values) < 2 or len(values) > MAX_INPUT
            or any(type(x) is not int or not -(1 << 63) <= x < (1 << 63) for x in values)):
        return None
    n = values[0]
    if not 1 <= n <= MAX_N or len(values) != 1 + n * n:
        return None
    d = [values[1 + i * n:1 + (i + 1) * n] for i in range(n)]
    if (any(not 0 <= d[i][j] <= 10000 for i in range(n) for j in range(n))
            or any(d[i][i] != 0 for i in range(n))
            or any(d[i][j] != d[j][i] for i in range(n) for j in range(n))
            or any(d[i][j] > d[i][k] + d[k][j]
                   for i in range(n) for j in range(n) for k in range(n))):
        return None
    return n, d


def _tour(n: int, d: list[list[int]]) -> list[int]:
    parent = list(range(n))

    def root(x: int) -> int:
        while parent[x] != x:
            x = parent[x]
        return x

    mult = [[0] * n for _ in range(n)]
    degree = [0] * n
    edges = sorted((d[u][v], u, v) for u in range(n) for v in range(u + 1, n))
    accepted = 0
    for _, u, v in edges:
        ru, rv = root(u), root(v)
        if ru != rv:
            parent[rv] = ru
            mult[u][v] += 1; mult[v][u] += 1
            degree[u] += 1; degree[v] += 1
            accepted += 1
            if accepted == n - 1:
                break

    odd = [v for v in range(n) if degree[v] & 1]
    full = (1 << len(odd)) - 1
    memo: dict[int, tuple[int, tuple[tuple[int, int], ...]]] = {0: (0, ())}

    def match(mask: int):
        if mask in memo:
            return memo[mask]
        i = next(i for i in range(len(odd)) if mask >> i & 1)
        rest = mask ^ (1 << i)
        best = None
        for j in range(i + 1, len(odd)):
            if not (rest >> j & 1):
                continue
            cost, pairs = match(rest ^ (1 << j))
            candidate = (cost + d[odd[i]][odd[j]], ((odd[i], odd[j]),) + pairs)
            if best is None or candidate < best:
                best = candidate
        assert best is not None
        memo[mask] = best
        return best

    _, pairs = match(full)
    for u, v in pairs:
        mult[u][v] += 1; mult[v][u] += 1

    stack = [0]
    reverse_circuit: list[int] = []
    while stack:
        v = stack[-1]
        w = next((x for x in range(n) if mult[v][x]), None)
        if w is None:
            reverse_circuit.append(stack.pop())
        else:
            mult[v][w] -= 1; mult[w][v] -= 1
            stack.append(w)
    circuit = list(reversed(reverse_circuit))
    seen: set[int] = set()
    order = []
    for v in circuit:
        if v not in seen:
            seen.add(v); order.append(v)
    return order


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
    parsed = _parse(values)
    if parsed is None:
        return -1, b""
    n, d = parsed
    order = _tour(n, d)
    tour = [*order, 0]
    cost = sum(d[tour[i]][tour[i + 1]] for i in range(n))
    output = b"".join(struct.pack("<q", x) for x in (cost, *tour))
    if output_is_null or capacity is not None and capacity < len(output):
        return -2, b""
    return len(output), output
