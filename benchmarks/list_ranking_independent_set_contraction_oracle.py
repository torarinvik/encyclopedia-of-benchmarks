"""Contraction oracle for the bounded encyclopedia list-ranking profile."""

from __future__ import annotations

import struct
from collections.abc import Sequence

MAX_N = 16
MAX_INPUT = 2 + 2 * MAX_N
MAX_INPUT_LENGTH = MAX_INPUT
MAX_OUTPUT_BYTES = 8 * MAX_N


def _parse(values: Sequence[int] | None):
    if (not isinstance(values, (list, tuple)) or len(values) < 4 or len(values) > MAX_INPUT
            or any(type(x) is not int or not -(1 << 63) <= x < (1 << 63) for x in values)):
        return None
    n, head = values[0], values[1]
    if not 1 <= n <= MAX_N or len(values) != 2 + 2 * n or not 0 <= head < n:
        return None
    weights = list(values[2:2 + n])
    successors = list(values[2 + n:])
    if any(not 1 <= weight <= 10000 for weight in weights):
        return None
    if any(successor < -1 or successor >= n for successor in successors):
        return None
    indegree = [0] * n
    for successor in successors:
        if successor >= 0:
            indegree[successor] += 1
            if indegree[successor] > 1:
                return None
    if indegree[head] != 0 or sum(successor == -1 for successor in successors) != 1:
        return None
    path = []
    seen = [False] * n
    node = head
    while node != -1:
        if seen[node]:
            return None
        seen[node] = True
        path.append(node)
        node = successors[node]
    if len(path) != n or not all(seen):
        return None
    return n, weights, path


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or capacity is not None and (type(capacity) is not int or capacity < 0)
            or input_length is not None and
            (type(input_length) is not int or not 0 <= input_length <= MAX_INPUT)
            or input_is_null and values not in (None, [], ())
            or not input_is_null and values is not None and input_length is not None
            and isinstance(values, (list, tuple))
            and input_length != len(values)):
        return -1, b""
    if input_is_null or values is None:
        return -1, b""
    parsed = _parse(values)
    if parsed is None:
        return -1, b""
    n, weights, path = parsed
    if output_is_null or capacity is not None and capacity < 8 * n:
        return -2, b""

    removed: list[tuple[int, int, int]] = []
    while len(path) > 1:
        counts = [sum(position % 3 == color for position in range(len(path) - 1))
                  for color in range(3)]
        color = max(range(3), key=lambda candidate: (counts[candidate], -candidate))
        reduced = []
        for position, node in enumerate(path):
            if position < len(path) - 1 and position % 3 == color:
                successor = path[position + 1]
                removed.append((node, successor, weights[successor]))
                weights[successor] += weights[node]
            else:
                reduced.append(node)
        path = reduced

    ranks = [0] * n
    ranks[path[0]] = weights[path[0]]
    for node, successor, old_successor_weight in reversed(removed):
        ranks[node] = ranks[successor] - old_successor_weight
    output = b"".join(struct.pack("<q", rank) for rank in ranks)
    return len(output), output
