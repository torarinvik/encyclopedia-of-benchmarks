"""D* Lite repairs shortest-path values as the start and edge costs change."""

from __future__ import annotations

from collections.abc import Sequence

MAX_SIDE = 4
MAX_VERTICES = 16
MAX_UPDATES = 16
MAX_EDGE_COST = 9
UNREACHABLE_CODE = 136
INFINITY = 1 << 60
MAX_VALID_INPUT_LENGTH = 198
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
INVALID_RESULT = -1


def _parse(values: Sequence[int] | None, input_is_null: bool,
           input_length: int | None):
    if type(input_is_null) is not bool or input_is_null or not isinstance(values, (list, tuple)):
        return None
    length = len(values) if input_length is None else input_length
    if (type(length) is not int or length < 6 or length > MAX_PARSEABLE_INPUT_LENGTH
            or length != len(values)):
        return None
    if any(type(value) is not int or not -(1 << 63) <= value < (1 << 63) for value in values):
        return None
    height, width, edge_count, update_count, start, goal = values[:6]
    if (not 1 <= height <= MAX_SIDE or not 1 <= width <= MAX_SIDE
            or not 2 <= height * width <= MAX_VERTICES
            or not 0 <= update_count <= MAX_UPDATES):
        return None
    vertex_count = height * width
    max_edges = 2 * (height * (width - 1) + width * (height - 1))
    if not 0 <= edge_count <= max_edges:
        return None
    if not (0 <= start < vertex_count and 0 <= goal < vertex_count):
        return None
    if length != 6 + 3 * edge_count + 3 * update_count:
        return None

    edges: list[list[int]] = []
    seen: set[tuple[int, int]] = set()
    edge_offset = 6
    for edge_id in range(edge_count):
        source, target, cost = values[edge_offset + 3 * edge_id:edge_offset + 3 * edge_id + 3]
        if not (0 <= source < vertex_count and 0 <= target < vertex_count and 1 <= cost <= MAX_EDGE_COST):
            return None
        source_row, source_column = divmod(source, width)
        target_row, target_column = divmod(target, width)
        if abs(source_row - target_row) + abs(source_column - target_column) != 1:
            return None
        if (source, target) in seen:
            return None
        seen.add((source, target))
        edges.append([source, target, cost])

    updates: list[tuple[int, int, int]] = []
    update_offset = edge_offset + 3 * edge_count
    for offset in range(update_offset, length, 3):
        new_start, edge_id, new_cost = values[offset:offset + 3]
        if not (0 <= new_start < vertex_count and 0 <= edge_id < edge_count
                and 1 <= new_cost <= MAX_EDGE_COST):
            return None
        updates.append((new_start, edge_id, new_cost))
    return height, width, start, goal, edges, updates


def _heuristic(a: int, b: int, width: int) -> int:
    row_a, column_a = divmod(a, width)
    row_b, column_b = divmod(b, width)
    return abs(row_a - row_b) + abs(column_a - column_b)


def _key(vertex: int, start: int, key_modifier: int, width: int,
         g: list[int], rhs: list[int]) -> tuple[int, int]:
    best_estimate = min(g[vertex], rhs[vertex])
    return (best_estimate + _heuristic(start, vertex, width) + key_modifier,
            best_estimate)


def _update_vertex(vertex: int, goal: int, start: int, key_modifier: int, width: int,
                   edges: list[list[int]], outgoing: list[list[int]], g: list[int],
                   rhs: list[int], is_open: list[bool], stored_keys: list[tuple[int, int]]) -> None:
    if vertex != goal:
        best = INFINITY
        for edge_id in outgoing[vertex]:
            _, target, cost = edges[edge_id]
            if g[target] < INFINITY:
                best = min(best, cost + g[target])
        rhs[vertex] = best
    is_open[vertex] = False
    if g[vertex] != rhs[vertex]:
        is_open[vertex] = True
        stored_keys[vertex] = _key(vertex, start, key_modifier, width, g, rhs)


def _compute_shortest_path(start: int, goal: int, key_modifier: int, width: int,
                           edges: list[list[int]], outgoing: list[list[int]],
                           incoming: list[list[int]], g: list[int], rhs: list[int],
                           is_open: list[bool], stored_keys: list[tuple[int, int]]) -> None:
    while True:
        candidates = [vertex for vertex, present in enumerate(is_open) if present]
        if not candidates:
            return
        top = min(candidates, key=lambda vertex: (*stored_keys[vertex], vertex))
        if not (stored_keys[top] < _key(start, start, key_modifier, width, g, rhs)
                or rhs[start] != g[start]):
            return

        old_key = stored_keys[top]
        is_open[top] = False
        new_key = _key(top, start, key_modifier, width, g, rhs)
        if old_key < new_key:
            is_open[top] = True
            stored_keys[top] = new_key
        elif g[top] > rhs[top]:
            g[top] = rhs[top]
            for edge_id in incoming[top]:
                predecessor = edges[edge_id][0]
                _update_vertex(predecessor, goal, start, key_modifier, width,
                               edges, outgoing, g, rhs, is_open, stored_keys)
        else:
            g[top] = INFINITY
            _update_vertex(top, goal, start, key_modifier, width,
                           edges, outgoing, g, rhs, is_open, stored_keys)
            for edge_id in incoming[top]:
                predecessor = edges[edge_id][0]
                _update_vertex(predecessor, goal, start, key_modifier, width,
                               edges, outgoing, g, rhs, is_open, stored_keys)


def _snapshot(start: int, goal: int, edges: list[list[int]], g: list[int]) -> tuple[int, int]:
    if g[start] >= INFINITY:
        return UNREACHABLE_CODE, 0
    if start == goal:
        return 0, 0
    successors = [
        target for source, target, cost in edges
        if source == start and g[target] < INFINITY and cost + g[target] == g[start]
    ]
    return g[start], (min(successors) + 1) if successors else 0


def expected_result(values: Sequence[int] | None, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    parsed = _parse(values, input_is_null, input_length)
    if parsed is None:
        return INVALID_RESULT
    height, width, start, goal, edges, updates = parsed
    vertex_count = height * width
    outgoing = [[] for _ in range(vertex_count)]
    incoming = [[] for _ in range(vertex_count)]
    for edge_id, (source, target, _) in enumerate(edges):
        outgoing[source].append(edge_id)
        incoming[target].append(edge_id)

    g = [INFINITY] * vertex_count
    rhs = [INFINITY] * vertex_count
    rhs[goal] = 0
    is_open = [False] * vertex_count
    stored_keys = [(0, 0)] * vertex_count
    is_open[goal] = True
    key_modifier = 0
    last_start = start
    stored_keys[goal] = _key(goal, start, key_modifier, width, g, rhs)

    checksum = 0
    for time_index, (new_start, edge_id, new_cost) in enumerate(updates, start=1):
        key_modifier += _heuristic(last_start, new_start, width)
        start = new_start
        last_start = new_start
        source = edges[edge_id][0]
        edges[edge_id][2] = new_cost
        _update_vertex(source, goal, start, key_modifier, width,
                       edges, outgoing, g, rhs, is_open, stored_keys)
        _compute_shortest_path(start, goal, key_modifier, width,
                               edges, outgoing, incoming, g, rhs, is_open, stored_keys)
        distance_code, next_code = _snapshot(start, goal, edges, g)
        checksum += time_index * (distance_code + 1) * (next_code + 1)
    return checksum
