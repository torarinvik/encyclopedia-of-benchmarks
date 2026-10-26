"""Independent all-pairs-distance verifier for GBBS low-diameter labels."""

from __future__ import annotations

from collections.abc import Sequence

MAX_NODES = 12
MAX_EDGES = 24
MAX_INPUT_LENGTH = 2 + 2 * MAX_EDGES
MAX_OUTPUT_BYTES = MAX_NODES
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1
BATCH_SIZES = (1, 1, 1, 1, 2, 2, 3, 4, 4, 6, 7, 9, 11)
INF = MAX_NODES + 1


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or capacity is not None and (type(capacity) is not int or capacity < 0)
            or input_length is not None and (type(input_length) is not int
                                             or not 0 <= input_length <= MAX_INPUT_LENGTH)
            or input_is_null and values not in (None, [], ())
            or not input_is_null and values is not None and input_length is not None
            and input_length != len(values)):
        return -1, b""
    if input_is_null or values is None:
        return -1, b""
    if (not isinstance(values, (list, tuple)) or len(values) < 2
            or len(values) > MAX_INPUT_LENGTH
            or any(type(value) is not int or not I64_MIN <= value <= I64_MAX
                   for value in values)):
        return -1, b""
    n, m = values[:2]
    if not 1 <= n <= MAX_NODES or not 0 <= m <= MAX_EDGES or len(values) != 2 + 2 * m:
        return -1, b""
    distance = [[INF] * n for _ in range(n)]
    for vertex in range(n):
        distance[vertex][vertex] = 0
    seen = set()
    for offset in range(2, len(values), 2):
        u, v = values[offset:offset + 2]
        if not 0 <= u < v < n or (u, v) in seen:
            return -1, b""
        seen.add((u, v))
        distance[u][v] = distance[v][u] = 1
    for middle in range(n):
        for left in range(n):
            for right in range(n):
                candidate = distance[left][middle] + distance[middle][right]
                if candidate < distance[left][right]:
                    distance[left][right] = candidate

    release_round = [-1] * n
    cursor = 0
    round_index = 0
    while cursor < n:
        end = min(n, cursor + BATCH_SIZES[round_index])
        for vertex in range(cursor, end):
            release_round[vertex] = round_index
        cursor = end
        round_index += 1

    labels = []
    for vertex in range(n):
        best = (INF, n)
        for center in range(n):
            rank = (release_round[center] + distance[center][vertex], center)
            if rank < best:
                best = rank
        labels.append(best[1])
    result = bytes(labels)
    if output_is_null or capacity is not None and capacity < n:
        return -2, b""
    return n, result
