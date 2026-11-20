"""Primary segment-tree/rollback-parity reference for bounded event traces."""

import struct
from typing import Sequence

MAX_VERTICES = 16
MAX_EVENTS = 64
MAX_VALID_INPUT_LENGTH = 2 + 4 * MAX_EVENTS
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_OUTPUT_BYTES = 8 * MAX_EVENTS
INVALID_RESULT = -1
OUTPUT_ERROR_RESULT = -2


def _parse(values: Sequence[int] | None, input_length: int | None,
           input_is_null: bool) -> tuple[int, int, list[tuple[int, int, int, int]],
                                          list[tuple[int, int, int, int]]] | None:
    if (input_is_null or not isinstance(values, (list, tuple))
            or len(values) < 2 or len(values) > MAX_PARSEABLE_INPUT_LENGTH
            or (input_length is not None
                and (type(input_length) is not int or input_length != len(values)
                     or not 0 <= input_length <= MAX_PARSEABLE_INPUT_LENGTH))
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return None
    vertex_count, event_count = values[:2]
    if not 1 <= vertex_count <= MAX_VERTICES or not 0 <= event_count <= MAX_EVENTS:
        return None
    if len(values) != 2 + 4 * event_count:
        return None

    events: list[tuple[int, int, int, int]] = []
    intervals: list[tuple[int, int, int, int]] = []
    used_ids: set[int] = set()
    active: dict[int, tuple[int, int, int]] = {}
    active_pairs: set[tuple[int, int]] = set()
    query_count = 0
    for time in range(event_count):
        operation, first, second, third = values[2 + 4 * time:6 + 4 * time]
        if operation == 0:
            edge_id, left, right = first, second, third
            if (not 0 <= edge_id < MAX_EVENTS or edge_id in used_ids
                    or not 0 <= left <= right < vertex_count
                    or (left, right) in active_pairs):
                return None
            used_ids.add(edge_id)
            active[edge_id] = (left, right, time)
            active_pairs.add((left, right))
        elif operation == 1:
            edge_id = first
            if edge_id not in active or second != 0 or third != 0:
                return None
            left, right, start = active.pop(edge_id)
            active_pairs.remove((left, right))
            intervals.append((start, time, left, right))
        elif operation == 2:
            if first != 0 or second != 0 or third != 0:
                return None
            query_count += 1
        else:
            return None
        events.append((operation, first, second, third))
    intervals.extend((start, event_count, left, right)
                     for left, right, start in active.values())
    return vertex_count, query_count, events, intervals


def _answers(vertex_count: int, events: list[tuple[int, int, int, int]],
             intervals: list[tuple[int, int, int, int]]) -> list[int]:
    event_count = len(events)
    if event_count == 0:
        return []
    tree: list[list[tuple[int, int]]] = [[] for _ in range(4 * event_count + 8)]

    def place(node: int, left: int, right: int, begin: int, end: int,
              edge: tuple[int, int]) -> None:
        if begin <= left and right <= end:
            tree[node].append(edge)
            return
        middle = left + (right - left) // 2
        if begin < middle:
            place(node * 2, left, middle, begin, end, edge)
        if end > middle:
            place(node * 2 + 1, middle, right, begin, end, edge)

    for begin, end, left, right in intervals:
        if begin < end:
            place(1, 0, event_count, begin, end, (left, right))

    parent = list(range(vertex_count))
    size = [1] * vertex_count
    xor_parent = [0] * vertex_count
    history: list[tuple[int, ...]] = []
    contradictions = 0
    answers = [0] * event_count

    def find(vertex: int) -> tuple[int, int]:
        parity = 0
        while parent[vertex] != vertex:
            parity ^= xor_parent[vertex]
            vertex = parent[vertex]
        return vertex, parity

    def add_edge(left: int, right: int) -> None:
        nonlocal contradictions
        root_left, parity_left = find(left)
        root_right, parity_right = find(right)
        if root_left == root_right:
            if parity_left ^ parity_right != 1:
                history.append((1,))
                contradictions += 1
            return
        if size[root_left] > size[root_right]:
            root_left, root_right = root_right, root_left
        history.append((0, root_left, root_right, size[root_right], xor_parent[root_left]))
        parent[root_left] = root_right
        xor_parent[root_left] = parity_left ^ parity_right ^ 1
        size[root_right] += size[root_left]

    def rollback(checkpoint: int) -> None:
        nonlocal contradictions
        while len(history) > checkpoint:
            record = history.pop()
            if record[0] == 1:
                contradictions -= 1
            else:
                _, child, root, old_size, old_xor = record
                parent[child] = child
                xor_parent[child] = old_xor
                size[root] = old_size

    def visit(node: int, left: int, right: int) -> None:
        checkpoint = len(history)
        for edge_left, edge_right in tree[node]:
            add_edge(edge_left, edge_right)
        if right - left == 1:
            if events[left][0] == 2:
                answers[left] = int(contradictions == 0)
        else:
            middle = left + (right - left) // 2
            visit(node * 2, left, middle)
            visit(node * 2 + 1, middle, right)
        rollback(checkpoint)

    visit(1, 0, event_count)
    return [answers[index] for index, event in enumerate(events) if event[0] == 2]


def expected_output(
    values: Sequence[int] | None,
    capacity: int | None = None,
    output_is_null: bool = False,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> tuple[int, bytes]:
    """Return ``(result, bytes)`` for ``[n,q,(op,a,b,c)*q]``.

    Add is ``[0,id,u,v]`` with canonical ``u<=v``; remove is
    ``[1,id,0,0]``; whole-graph bipartiteness query is ``[2,0,0,0]``.
    Edge IDs are single-use and parallel active edges are rejected. Self-loops
    are valid and create parity contradictions.
    """
    parsed = _parse(values, input_length, input_is_null)
    if parsed is None:
        return INVALID_RESULT, b""
    vertex_count, query_count, events, intervals = parsed
    effective_capacity = MAX_OUTPUT_BYTES if capacity is None else capacity
    if (type(output_is_null) is not bool or type(effective_capacity) is not int
            or effective_capacity < 0 or output_is_null
            or effective_capacity < 8 * query_count):
        return OUTPUT_ERROR_RESULT, b""
    payload = b"".join(struct.pack("<q", answer)
                      for answer in _answers(vertex_count, events, intervals))
    return len(payload), payload
