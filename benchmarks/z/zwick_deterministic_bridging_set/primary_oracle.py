"""Source-style bounded deterministic witness-prefix bridge-set construction."""

from __future__ import annotations

MAX_N = 8
MAX_VALID_INPUT_LENGTH = 130
MAX_PARSEABLE_INPUT_LENGTH = 131
WORKSPACE_BYTES = 4096


def _decode(values: list[int] | tuple[int, ...] | None, input_is_null: bool,
            input_length: int | None) -> tuple[int, int, list[list[int]], list[list[int]]] | None:
    if input_is_null or values is None:
        return None
    if input_length is not None and input_length != len(values):
        return None
    if not 2 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH:
        return None
    if any(type(value) is not int or value < -(1 << 63) or value >= (1 << 63)
           for value in values):
        return None
    n, s = values[0], values[1]
    if not 2 <= n <= MAX_N or not 2 <= s <= n:
        return None
    if len(values) != 2 + 2 * n * n:
        return None
    edge_words = values[2:2 + n * n]
    witness_words = values[2 + n * n:]
    if any(value not in (0, 1) for value in edge_words):
        return None
    if any(value < 0 or value > n for value in witness_words):
        return None
    graph = [[edge_words[i * n + j] for j in range(n)] for i in range(n)]
    witness = [[witness_words[i * n + j] for j in range(n)] for i in range(n)]
    if any(graph[i][i] for i in range(n)):
        return None
    inf = n + 1
    dist = [[0 if i == j else (1 if graph[i][j] else inf) for j in range(n)]
            for i in range(n)]
    for k in range(n):
        for i in range(n):
            for j in range(n):
                candidate = dist[i][k] + dist[k][j]
                if candidate < dist[i][j]:
                    dist[i][j] = candidate
    if any(dist[i][j] >= inf for i in range(n) for j in range(n)):
        return None
    for i in range(n):
        for j in range(n):
            w = witness[i][j]
            if dist[i][j] <= 1:
                if w != 0:
                    return None
                if i != j and dist[i][j] == 1 and not graph[i][j]:
                    return None
            else:
                if w == 0:
                    return None
                v = w - 1
                if v == i or v == j:
                    return None
                if dist[i][v] + dist[v][j] != dist[i][j]:
                    return None
                if dist[i][v] >= dist[i][j] or dist[v][j] >= dist[i][j]:
                    return None
    return n, s, graph, witness


def _subpath(i: int, j: int, limit: int,
             witness: list[list[int]]) -> list[int]:
    """Return the first `limit` internal vertices by Figure 11 recursion."""
    if limit <= 0 or witness[i][j] == 0:
        return []
    middle = witness[i][j] - 1
    prefix = _subpath(i, middle, limit - 1, witness)
    prefix.append(middle)
    remaining = limit - len(prefix)
    if remaining > 0:
        prefix.extend(_subpath(middle, j, remaining, witness))
    return prefix


def _greedy(constraints: list[int], n: int) -> int:
    unhit = [True] * len(constraints)
    selected = 0
    left = len(constraints)
    while left:
        scores = [sum(1 for idx, mask in enumerate(constraints)
                      if unhit[idx] and mask & (1 << vertex))
                  for vertex in range(n)]
        best_score = max(scores, default=0)
        if best_score == 0:
            return -1
        chosen = next(vertex for vertex, score in enumerate(scores)
                      if score == best_score)
        selected |= 1 << chosen
        for idx, mask in enumerate(constraints):
            if unhit[idx] and mask & (1 << chosen):
                unhit[idx] = False
                left -= 1
    return selected


def expected_result(values: list[int] | tuple[int, ...] | None,
                    input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    parsed = _decode(values, input_is_null, input_length)
    if parsed is None:
        return -1
    n, s, _graph, witness = parsed
    constraints: list[int] = []
    for i in range(n):
        for j in range(n):
            mask = (1 << i) | (1 << j)
            for vertex in _subpath(i, j, s, witness):
                mask |= 1 << vertex
            if mask.bit_count() >= s and mask not in constraints:
                constraints.append(mask)
    return _greedy(constraints, n)
