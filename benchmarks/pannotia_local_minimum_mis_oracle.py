"""Independent priority-ordered MIS oracle for the bounded Pannotia profile."""

from __future__ import annotations

import struct

MAX_NODES = 16
MAX_EDGES = 64
MAX_PRIORITY = 99_999_998
MAX_INPUT_LENGTH = 2 + MAX_NODES + 2 * MAX_EDGES
MAX_OUTPUT_BYTES = 8 * MAX_NODES


def expected_output(values, capacity=None, output_is_null=False,
                    input_is_null=False, input_length=None):
    """Return (status, bytes), using sequential priority-order greedy MIS."""
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
    priorities = list(values[2:2 + n])
    if (any(not 0 <= priority <= MAX_PRIORITY for priority in priorities)
            or len(set(priorities)) != n):
        return -1, b""
    adjacency = [0] * n
    seen = set()
    for offset in range(2 + n, len(values), 2):
        u, v = values[offset:offset + 2]
        if not (0 <= u < v < n) or (u, v) in seen:
            return -1, b""
        seen.add((u, v))
        adjacency[u] |= 1 << v
        adjacency[v] |= 1 << u

    selected = [False] * n
    for vertex in sorted(range(n), key=lambda item: priorities[item]):
        neighbors = adjacency[vertex]
        if any(selected[other] for other in range(n)
               if (neighbors >> other) & 1):
            continue
        selected[vertex] = True
    output = b"".join(struct.pack("<q", 2 if chosen else 0)
                      for chosen in selected)
    if output_is_null or capacity is not None and capacity < len(output):
        return -2, b""
    return len(output), output
