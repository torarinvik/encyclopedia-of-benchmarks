"""Independent dense-neighbor oracle for Pannotia priority-extrema coloring."""

from __future__ import annotations

import struct

MAX_NODES = 16
MAX_EDGES = 64
MAX_PRIORITY = 99_999_998
MAX_INPUT_LENGTH = 3 + MAX_NODES + 2 * MAX_EDGES
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
    if len(values) < 3:
        return -1, b""
    n, m, mode = values[:3]
    if not 1 <= n <= MAX_NODES or not 0 <= m <= MAX_EDGES or mode not in (0, 1):
        return -1, b""
    if len(values) != 3 + n + 2 * m:
        return -1, b""
    priority = list(values[3:3 + n])
    if (any(not 0 <= rank <= MAX_PRIORITY for rank in priority)
            or len(set(priority)) != n):
        return -1, b""
    neighbors = [set() for _ in range(n)]
    edges = set()
    for index in range(3 + n, len(values), 2):
        left, right = values[index:index + 2]
        if not (0 <= left < right < n) or (left, right) in edges:
            return -1, b""
        edges.add((left, right))
        neighbors[left].add(right)
        neighbors[right].add(left)
    if any(len(row) == 1 for row in neighbors):
        return -1, b""

    color_ids = [0] * n
    uncolored = set(range(n))
    current_color = 1
    while uncolored:
        winners = []
        for vertex in sorted(uncolored):
            adjacent_priorities = [priority[other] for other in neighbors[vertex]
                                   if other in uncolored]
            if not adjacent_priorities or priority[vertex] > max(adjacent_priorities):
                color_ids[vertex] = current_color
                winners.append(vertex)
            if mode == 1 and (not adjacent_priorities
                              or priority[vertex] < min(adjacent_priorities)):
                color_ids[vertex] = current_color + 1
                if vertex not in winners:
                    winners.append(vertex)
        if not winners:
            return -1, b""
        uncolored.difference_update(winners)
        current_color += 2 if mode == 1 else 1

    output = b"".join(struct.pack("<q", value) for value in color_ids)
    if output_is_null or capacity is not None and capacity < len(output):
        return -2, b""
    return len(output), output
