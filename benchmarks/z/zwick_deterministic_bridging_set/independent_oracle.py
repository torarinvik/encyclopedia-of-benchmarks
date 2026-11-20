"""Iterative full-path bridge-set reference, independent of recursive sub-path."""

from __future__ import annotations

MAX_N = 8
MAX_PARSEABLE_INPUT_LENGTH = 131


def _read(values: list[int] | tuple[int, ...] | None, input_is_null: bool,
          input_length: int | None):
    if input_is_null or values is None:
        return None
    if input_length is not None and input_length != len(values):
        return None
    if not 2 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH:
        return None
    if any(type(x) is not int or x < -(1 << 63) or x >= (1 << 63) for x in values):
        return None
    n, threshold = values[0], values[1]
    if not 2 <= n <= MAX_N or not 2 <= threshold <= n or len(values) != 2 + 2 * n * n:
        return None
    edge = values[2:2 + n * n]
    witness_flat = values[2 + n * n:]
    if any(x not in (0, 1) for x in edge) or any(x < 0 or x > n for x in witness_flat):
        return None
    graph = [edge[r * n:(r + 1) * n] for r in range(n)]
    witness = [witness_flat[r * n:(r + 1) * n] for r in range(n)]
    if any(graph[i][i] for i in range(n)):
        return None
    inf = n + 1
    distance = [[0 if i == j else (1 if graph[i][j] else inf) for j in range(n)]
                for i in range(n)]
    for k in range(n):
        for i in range(n):
            for j in range(n):
                distance[i][j] = min(distance[i][j], distance[i][k] + distance[k][j])
    if any(distance[i][j] >= inf for i in range(n) for j in range(n)):
        return None
    for i in range(n):
        for j in range(n):
            w = witness[i][j]
            if distance[i][j] <= 1:
                if w != 0:
                    return None
            else:
                if w == 0:
                    return None
                v = w - 1
                if (v == i or v == j
                        or distance[i][v] + distance[v][j] != distance[i][j]
                        or distance[i][v] >= distance[i][j]
                        or distance[v][j] >= distance[i][j]):
                    return None
    return n, threshold, graph, witness


def _materialize_path(start: int, finish: int, witness: list[list[int]]) -> list[int]:
    path = [start]
    pending = [(start, finish)]
    while pending:
        left, right = pending.pop()
        encoded = witness[left][right]
        if encoded == 0:
            if left != right:
                path.append(right)
        else:
            middle = encoded - 1
            pending.append((middle, right))
            pending.append((left, middle))
    return path


def expected_result(values: list[int] | tuple[int, ...] | None,
                    input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    parsed = _read(values, input_is_null, input_length)
    if parsed is None:
        return -1
    n, threshold, _graph, witness = parsed
    constraints: list[int] = []
    for start in range(n):
        for finish in range(n):
            path = _materialize_path(start, finish, witness)
            mask = (1 << start) | (1 << finish)
            for vertex in path[1:-1][:threshold]:
                mask |= 1 << vertex
            if mask.bit_count() >= threshold and mask not in constraints:
                constraints.append(mask)
    chosen = 0
    active = [True] * len(constraints)
    remaining = len(constraints)
    while remaining:
        best_vertex = 0
        best_count = -1
        for vertex in range(n):
            score = sum(active[k] and bool(mask & (1 << vertex))
                        for k, mask in enumerate(constraints))
            if score > best_count:
                best_vertex, best_count = vertex, score
        if best_count <= 0:
            return -1
        chosen |= 1 << best_vertex
        for k, mask in enumerate(constraints):
            if active[k] and mask & (1 << best_vertex):
                active[k] = False
                remaining -= 1
    return chosen
