"""Reference oracle for predecessor-constrained DFS event output."""

from __future__ import annotations

import struct
from collections.abc import Sequence

MIN_NODES = 1
MAX_NODES = 16
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1
MAX_VALID_INPUT_LENGTH = 2 + MAX_NODES * MAX_NODES
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH
MAX_PARSEABLE_INPUT_VALUES = MAX_PARSEABLE_INPUT_LENGTH
MAX_INPUT_LENGTH = MAX_PARSEABLE_INPUT_LENGTH
MAX_EVENT_COUNT = MAX_NODES + MAX_NODES * (MAX_NODES - 1) // 2
MAX_OUTPUT_BYTES = 12 * MAX_EVENT_COUNT
INVALID_RESULT = -1
OUTPUT_ERROR_RESULT = -2


def expected_output(
    values: Sequence[int],
    output_capacity: int = MAX_OUTPUT_BYTES,
    output_is_null: bool = False,
    input_is_null: bool = False,
) -> tuple[int, bytes]:
    """Return the event byte count and bytes, or the ABI error sentinel."""
    if type(input_is_null) is not bool or type(output_is_null) is not bool:
        return INVALID_RESULT, b""
    if input_is_null:
        return INVALID_RESULT, b""
    if (
        not isinstance(values, (list, tuple))
        or not 2 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
        or any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values)
    ):
        return INVALID_RESULT, b""

    count, start = values[0], values[1]
    if not MIN_NODES <= count <= MAX_NODES or not 0 <= start < count:
        return INVALID_RESULT, b""
    if len(values) != 2 + count * count:
        return INVALID_RESULT, b""

    matrix = values[2:]
    if any(bit not in (0, 1) for bit in matrix):
        return INVALID_RESULT, b""
    if any(matrix[node * count + node] for node in range(count)):
        return INVALID_RESULT, b""

    successors: list[list[int]] = [[] for _ in range(count)]
    predecessors: list[list[int]] = [[] for _ in range(count)]
    indegree = [0] * count
    for source in range(count):
        for target in range(count):
            if matrix[source * count + target]:
                successors[source].append(target)
                predecessors[target].append(source)
                indegree[target] += 1

    # Kahn's pass rejects cycles anywhere in the packed graph, not just reachable ones.
    ready = [node for node, degree in enumerate(indegree) if degree == 0]
    topological_count = 0
    cursor = 0
    while cursor < len(ready):
        node = ready[cursor]
        cursor += 1
        topological_count += 1
        for child in successors[node]:
            indegree[child] -= 1
            if indegree[child] == 0:
                ready.append(child)
    if topological_count != count:
        return INVALID_RESULT, b""

    if type(output_capacity) is not int or output_capacity < 0:
        return INVALID_RESULT, b""
    visited = [False] * count
    events: list[tuple[int, int, int]] = []
    order = 0

    def visit(node: int) -> None:
        nonlocal order
        visited[node] = True
        events.append((1, node, order))
        order += 1
        for child in successors[node]:
            if visited[child]:
                continue
            if all(visited[parent] for parent in predecessors[child]):
                visit(child)
            else:
                events.append((0, child, -1))

    visit(start)
    output = b"".join(struct.pack("<iii", *event) for event in events)
    if output_is_null or output_capacity < len(output):
        return OUTPUT_ERROR_RESULT, b""
    return len(output), output
