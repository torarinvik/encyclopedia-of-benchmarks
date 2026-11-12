"""Direct-BFS oracle for bounded offline dynamic connectivity traces."""

from collections import deque
import struct
from typing import Sequence

MAX_VERTICES = 16
MAX_EVENTS = 32
MAX_VALID_INPUT_LENGTH = 2 + 4 * MAX_EVENTS
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_OUTPUT_BYTES = MAX_EVENTS * 8
INVALID_RESULT = -1
OUTPUT_ERROR_RESULT = -2


def _connected(vertex_count: int, edges: Sequence[tuple[int, int]],
               source: int, target: int) -> int:
    adjacency: list[list[int]] = [[] for _ in range(vertex_count)]
    for left, right in edges:
        adjacency[left].append(right)
        adjacency[right].append(left)
    seen = [False] * vertex_count
    seen[source] = True
    queue = deque([source])
    while queue:
        vertex = queue.popleft()
        if vertex == target:
            return 1
        for neighbor in adjacency[vertex]:
            if not seen[neighbor]:
                seen[neighbor] = True
                queue.append(neighbor)
    return 0


def expected_output(
    values: Sequence[int] | None,
    capacity: int | None = None,
    output_is_null: bool = False,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> tuple[int, bytes]:
    """Return ``(result, bytes)`` for ``[n,q,(op,a,b,c)*q]``.

    Event encodings are add ``[0,id,u,v]``, remove ``[1,id,0,0]``, and
    connectivity query ``[2,u,v,0]``. Edge identifiers are single-use. Each
    query is answered by a fresh BFS over the currently active edge set.
    """
    if (input_is_null or not isinstance(values, (list, tuple))
            or len(values) < 2 or len(values) > MAX_PARSEABLE_INPUT_LENGTH
            or (input_length is not None
                and (type(input_length) is not int
                     or input_length != len(values)
                     or not 0 <= input_length <= MAX_PARSEABLE_INPUT_LENGTH))
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return INVALID_RESULT, b""

    vertex_count, event_count = values[:2]
    if not 1 <= vertex_count <= MAX_VERTICES or not 0 <= event_count <= MAX_EVENTS:
        return INVALID_RESULT, b""
    if len(values) != 2 + 4 * event_count:
        return INVALID_RESULT, b""

    events: list[tuple[int, int, int, int]] = []
    used_ids: set[int] = set()
    active: dict[int, tuple[int, int]] = {}
    query_count = 0
    for time in range(event_count):
        operation, first, second, third = values[2 + 4 * time: 6 + 4 * time]
        if operation == 0:
            edge_id, left, right = first, second, third
            if (not 0 <= edge_id < MAX_EVENTS or edge_id in used_ids
                    or not 0 <= left < vertex_count or not 0 <= right < vertex_count):
                return INVALID_RESULT, b""
            used_ids.add(edge_id)
            active[edge_id] = (left, right)
        elif operation == 1:
            edge_id = first
            if edge_id not in active or second != 0 or third != 0:
                return INVALID_RESULT, b""
            del active[edge_id]
        elif operation == 2:
            if (not 0 <= first < vertex_count or not 0 <= second < vertex_count
                    or third != 0):
                return INVALID_RESULT, b""
            query_count += 1
        else:
            return INVALID_RESULT, b""
        events.append((operation, first, second, third))

    required = 8 * query_count
    effective_capacity = MAX_OUTPUT_BYTES if capacity is None else capacity
    if (type(output_is_null) is not bool or type(effective_capacity) is not int
            or effective_capacity < 0):
        return OUTPUT_ERROR_RESULT, b""
    if output_is_null or effective_capacity < required:
        return OUTPUT_ERROR_RESULT, b""

    active.clear()
    answers: list[int] = []
    for operation, first, second, third in events:
        if operation == 0:
            active[first] = (second, third)
        elif operation == 1:
            del active[first]
        else:
            answers.append(_connected(vertex_count, tuple(active.values()), first, second))

    payload = b"".join(struct.pack("<q", answer) for answer in answers)
    return len(payload), payload
