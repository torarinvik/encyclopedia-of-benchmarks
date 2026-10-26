"""Independent active-set oracle for the Pannotia priority-local-minimum MIS."""

from __future__ import annotations

import struct

MAX_NODES = 16
MAX_EDGES = 64
MAX_PRIORITY = 99_999_998
MAX_INPUT_LENGTH = 2 + MAX_NODES + 2 * MAX_EDGES
MAX_OUTPUT_BYTES = 8 * MAX_NODES


def expected_output(values, capacity=None, output_is_null=False,
                    input_is_null=False, input_length=None):
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or capacity is not None and (type(capacity) is not int or capacity < 0)
            or input_length is not None and (type(input_length) is not int
                                              or not 0 <= input_length <= MAX_INPUT_LENGTH)):
        return -1, b""
    if input_is_null or values is None:
        return -1, b""
    if (not isinstance(values, (tuple, list)) or len(values) > MAX_INPUT_LENGTH
            or any(type(value) is not int for value in values)
            or input_length is not None and input_length != len(values)):
        return -1, b""
    if len(values) < 2:
        return -1, b""
    n, m = values[:2]
    if not 1 <= n <= MAX_NODES or not 0 <= m <= MAX_EDGES:
        return -1, b""
    if len(values) != 2 + n + 2 * m:
        return -1, b""
    priority = list(values[2:2 + n])
    if (any(not 0 <= rank <= MAX_PRIORITY for rank in priority)
            or len(set(priority)) != n):
        return -1, b""
    neighbors = [set() for _ in range(n)]
    edges = set()
    for index in range(2 + n, len(values), 2):
        left, right = values[index:index + 2]
        if not (0 <= left < right < n) or (left, right) in edges:
            return -1, b""
        edges.add((left, right))
        neighbors[left].add(right)
        neighbors[right].add(left)

    active = [True] * n
    chosen = [False] * n
    while any(active):
        round_winners = [vertex for vertex in range(n) if active[vertex]
                         and all(priority[vertex] < priority[other]
                                 for other in neighbors[vertex] if active[other])]
        if not round_winners:
            return -1, b""
        removed = set(round_winners)
        for vertex in round_winners:
            chosen[vertex] = True
            removed.update(neighbors[vertex])
        for vertex in removed:
            active[vertex] = False

    output = b"".join(struct.pack("<q", 2 if value else 0) for value in chosen)
    if output_is_null or capacity is not None and capacity < len(output):
        return -2, b""
    return len(output), output
