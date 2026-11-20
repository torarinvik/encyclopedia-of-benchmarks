"""Independent graph-rebuild reference for offline dynamic bipartiteness."""

from collections import deque
import struct
from typing import Sequence

MAX_VERTICES = 16
MAX_EVENTS = 64
MAX_VALID_INPUT_LENGTH = 2 + 4 * MAX_EVENTS
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_OUTPUT_BYTES = 8 * MAX_EVENTS
INVALID_RESULT = -1
OUTPUT_ERROR_RESULT = -2


def _is_bipartite(vertex_count: int, edges: Sequence[tuple[int, int]]) -> int:
    adjacency: list[list[int]] = [[] for _ in range(vertex_count)]
    for left, right in edges:
        adjacency[left].append(right)
        adjacency[right].append(left)
    color = [-1] * vertex_count
    for start in range(vertex_count):
        if color[start] != -1:
            continue
        color[start] = 0
        queue = deque([start])
        while queue:
            vertex = queue.popleft()
            for neighbor in adjacency[vertex]:
                if color[neighbor] == -1:
                    color[neighbor] = color[vertex] ^ 1
                    queue.append(neighbor)
                elif color[neighbor] == color[vertex]:
                    return 0
    return 1


def expected_output(
    values: Sequence[int] | None,
    capacity: int | None = None,
    output_is_null: bool = False,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> tuple[int, bytes]:
    if (input_is_null or not isinstance(values, (list, tuple))
            or len(values) < 2 or len(values) > MAX_PARSEABLE_INPUT_LENGTH
            or (input_length is not None
                and (type(input_length) is not int or input_length != len(values)
                     or not 0 <= input_length <= MAX_PARSEABLE_INPUT_LENGTH))
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return INVALID_RESULT, b""

    vertex_count, event_count = values[:2]
    if not 1 <= vertex_count <= MAX_VERTICES or not 0 <= event_count <= MAX_EVENTS:
        return INVALID_RESULT, b""
    if len(values) != 2 + 4 * event_count:
        return INVALID_RESULT, b""

    trace: list[tuple[int, int, int, int]] = []
    seen_ids: set[int] = set()
    active: dict[int, tuple[int, int]] = {}
    active_edges: set[tuple[int, int]] = set()
    query_count = 0
    for index in range(event_count):
        operation, first, second, third = values[2 + index * 4:6 + index * 4]
        if operation == 0:
            edge_id, left, right = first, second, third
            if (not 0 <= edge_id < MAX_EVENTS or edge_id in seen_ids
                    or not 0 <= left <= right < vertex_count
                    or (left, right) in active_edges):
                return INVALID_RESULT, b""
            seen_ids.add(edge_id)
            active[edge_id] = (left, right)
            active_edges.add((left, right))
        elif operation == 1:
            edge_id = first
            if edge_id not in active or second != 0 or third != 0:
                return INVALID_RESULT, b""
            active_edges.remove(active.pop(edge_id))
        elif operation == 2:
            if first != 0 or second != 0 or third != 0:
                return INVALID_RESULT, b""
            query_count += 1
        else:
            return INVALID_RESULT, b""
        trace.append((operation, first, second, third))

    effective_capacity = MAX_OUTPUT_BYTES if capacity is None else capacity
    if (type(output_is_null) is not bool or type(effective_capacity) is not int
            or effective_capacity < 0 or output_is_null
            or effective_capacity < 8 * query_count):
        return OUTPUT_ERROR_RESULT, b""

    active.clear()
    answers: list[int] = []
    for operation, first, second, third in trace:
        if operation == 0:
            active[first] = (second, third)
        elif operation == 1:
            del active[first]
        else:
            answers.append(_is_bipartite(vertex_count, tuple(active.values())))
    payload = b"".join(struct.pack("<q", answer) for answer in answers)
    return len(payload), payload
