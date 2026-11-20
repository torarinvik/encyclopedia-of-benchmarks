"""LDFS+ followed by Rightmost-Neighbor path cover, for bounded inputs."""

from __future__ import annotations

from collections.abc import Sequence

MIN_VERTICES = 1
MAX_VERTICES = 8
MAX_VALID_INPUT_LENGTH = 1 + 2 * MAX_VERTICES
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_RESULT = MAX_VERTICES
WORKSPACE_BYTES = 4096
INVALID_RESULT = -1


def _parse(values: Sequence[int] | None, input_is_null: bool,
           input_length: int | None) -> tuple[int, list[int], list[int]] | None:
    if (type(input_is_null) is not bool or input_is_null or values is None
            or not isinstance(values, (list, tuple))
            or not 1 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
            or (input_length is not None
                and (type(input_length) is not int or input_length != len(values)))
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return None
    n = values[0]
    if not MIN_VERTICES <= n <= MAX_VERTICES or len(values) != 1 + 2 * n:
        return None
    rows = list(values[1:1 + n])
    order = list(values[1 + n:])
    full_mask = (1 << n) - 1
    if any(row < 0 or row & ~full_mask or row & (1 << vertex)
           for vertex, row in enumerate(rows)):
        return None
    if any((rows[u] >> v) & 1 != (rows[v] >> u) & 1
           for u in range(n) for v in range(n)):
        return None
    if sorted(order) != list(range(n)):
        return None

    reached = 1
    frontier = reached
    while frontier:
        neighbors = 0
        bits = frontier
        while bits:
            bit = bits & -bits
            vertex = bit.bit_length() - 1
            neighbors |= rows[vertex]
            bits ^= bit
        frontier = neighbors & ~reached
        reached |= frontier
    if reached != full_mask:
        return None

    position = [0] * n
    for rank, vertex in enumerate(order):
        position[vertex] = rank
    for i in range(n):
        left = order[i]
        for j in range(i + 1, n):
            middle = order[j]
            for k in range(j + 1, n):
                right = order[k]
                if (rows[left] >> right) & 1 and not (
                    ((rows[left] >> middle) & 1) or ((rows[middle] >> right) & 1)
                ):
                    return None
    return n, rows, order


def _ldfs_plus(rows: list[int], order: list[int]) -> list[int]:
    n = len(rows)
    rank = [0] * n
    for index, vertex in enumerate(order):
        rank[vertex] = index
    labels: list[list[int]] = [[] for _ in range(n)]
    unvisited = set(range(n))
    result: list[int] = []
    for step in range(1, n + 1):
        chosen = max(unvisited, key=lambda vertex: (tuple(labels[vertex]), rank[vertex]))
        result.append(chosen)
        unvisited.remove(chosen)
        for neighbor in range(n):
            if neighbor in unvisited and ((rows[chosen] >> neighbor) & 1):
                labels[neighbor].insert(0, step)
    return result


def _rightmost_neighbor_count(rows: list[int], ordering: list[int]) -> int:
    rank = [0] * len(rows)
    for index, vertex in enumerate(ordering):
        rank[vertex] = index
    unvisited = set(range(len(rows)))
    paths = 0
    while unvisited:
        current = max(unvisited, key=rank.__getitem__)
        unvisited.remove(current)
        paths += 1
        while True:
            candidates = [vertex for vertex in unvisited
                          if (rows[current] >> vertex) & 1]
            if not candidates:
                break
            current = max(candidates, key=rank.__getitem__)
            unvisited.remove(current)
    return paths


def expected_result(values: Sequence[int] | None, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    parsed = _parse(values, input_is_null, input_length)
    if parsed is None:
        return INVALID_RESULT
    _, rows, order = parsed
    return _rightmost_neighbor_count(rows, _ldfs_plus(rows, order))
