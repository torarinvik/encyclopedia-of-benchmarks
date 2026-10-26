"""Independent stack-machine verifier for GBBS Yoshida MIS queries."""

from __future__ import annotations

import struct

MAX_NODES = 12
MAX_EDGES = 24
MAX_QUERY_CUTOFF = 128
MAX_INPUT_LENGTH = 4 + 2 * MAX_EDGES
OUTPUT_BYTES = 16
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1
MASK64 = (1 << 64) - 1


def _priority(vertex: int) -> int:
    value = (vertex * 3935559000370003845 + 2691343689449507681) & MASK64
    value ^= value >> 21
    value ^= (value << 37) & MASK64
    value ^= value >> 4
    value = value * 4768777513237032717 & MASK64
    value ^= (value << 20) & MASK64
    value ^= value >> 41
    value ^= (value << 5) & MASK64
    return value


def expected_output(values, capacity=None, output_is_null=False,
                    input_is_null=False, input_length=None):
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
    if (not isinstance(values, (tuple, list)) or len(values) < 4
            or len(values) > MAX_INPUT_LENGTH
            or any(type(item) is not int or not I64_MIN <= item <= I64_MAX
                   for item in values)):
        return -1, b""
    n, m, root, cutoff = values[:4]
    if (not 1 <= n <= MAX_NODES or not 0 <= m <= MAX_EDGES
            or not 0 <= root < n or not 0 <= cutoff <= MAX_QUERY_CUTOFF
            or len(values) != 4 + 2 * m):
        return -1, b""
    adjacency = [[] for _ in range(n)]
    seen = set()
    for pos in range(4, len(values), 2):
        left, right = values[pos:pos + 2]
        if not 0 <= left < right < n or (left, right) in seen:
            return -1, b""
        seen.add((left, right))
        adjacency[left].append(right)
        adjacency[right].append(left)
    priority = [_priority(vertex) for vertex in range(n)]
    for row in adjacency:
        row.sort(key=lambda vertex: (priority[vertex], vertex))

    # Execute the depth-first query with explicit frames rather than recursive
    # calls. Each frame stores a node and the next priority-ordered neighbor.
    stack = [[root, 0]]
    work = 0
    returned = None
    while stack:
        vertex, cursor = stack[-1]
        if returned is not None:
            if returned == 1:
                stack.pop()
                returned = 0
                continue
            if returned == -1:
                stack.pop()
                continue
            returned = None  # child is out; continue scanning this frame
        if cursor == len(adjacency[vertex]):
            stack.pop()
            returned = 1
            continue
        if work == cutoff:
            stack.pop()
            returned = -1
            continue
        neighbor = adjacency[vertex][cursor]
        stack[-1][1] += 1
        work += 1
        if (priority[vertex] < priority[neighbor]
                or priority[vertex] == priority[neighbor] and vertex <= neighbor):
            stack.pop()
            returned = 1
            continue
        stack.append([neighbor, 0])

    # The last returned status belongs to the root. A child result of out is
    # consumed by its parent; unknown propagates unchanged up the stack.
    status = returned
    output = struct.pack("<qq", status, work)
    if output_is_null or capacity is not None and capacity < OUTPUT_BYTES:
        return -2, b""
    return OUTPUT_BYTES, output
