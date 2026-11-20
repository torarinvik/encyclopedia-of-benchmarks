"""D* Lite incremental replanning over a bounded directed grid graph."""

from __future__ import annotations

from collections.abc import Sequence

MAX_SIDE = 4
MAX_VERTICES = 16
MAX_UPDATES = 16
MAX_EDGE_COST = 9
UNREACHABLE_CODE = 136
INFINITY = 1 << 60
MAX_VALID_INPUT_LENGTH = 198
MAX_PARSEABLE_INPUT_LENGTH = 199
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
    edge_by_pair: dict[tuple[int, int], int] = {}
    edge_offset = 6
    for edge_id in range(edge_count):
        source, target, cost = values[edge_offset + 3 * edge_id:edge_offset + 3 * edge_id + 3]
        if not (0 <= source < vertex_count and 0 <= target < vertex_count and 1 <= cost <= MAX_EDGE_COST):
            return None
        source_row, source_column = divmod(source, width)
        target_row, target_column = divmod(target, width)
        if abs(source_row - target_row) + abs(source_column - target_column) != 1:
            return None
        if (source, target) in edge_by_pair:
            return None
        edge_by_pair[(source, target)] = edge_id
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


def _manhattan(a: int, b: int, width: int) -> int:
    row_a, column_a = divmod(a, width)
    row_b, column_b = divmod(b, width)
    return abs(row_a - row_b) + abs(column_a - column_b)


def _encode_snapshot(start: int, goal: int,
                     edges: list[list[int]], distances: list[int]) -> tuple[int, int]:
    distance = distances[start]
    if distance >= INFINITY:
        return UNREACHABLE_CODE, 0
    if start == goal:
        return 0, 0
    successors = [
        target for source, target, cost in edges
        if source == start and cost + distances[target] == distance
    ]
    return distance, (min(successors) + 1) if successors else 0


def expected_result(values: Sequence[int] | None, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    parsed = _parse(values, input_is_null, input_length)
    if parsed is None:
        return INVALID_RESULT
    height, width, start, goal, edges, updates = parsed
    vertex_count = height * width
    checksum = 0
    for time_index, (new_start, edge_id, new_cost) in enumerate(updates, start=1):
        start = new_start
        edges[edge_id][2] = new_cost

        all_pairs = [INFINITY] * (vertex_count * vertex_count)
        for vertex in range(vertex_count):
            all_pairs[vertex * vertex_count + vertex] = 0
        for edge_source, edge_target, cost in edges:
            all_pairs[edge_source * vertex_count + edge_target] = cost
        for middle in range(vertex_count):
            middle_row = middle * vertex_count
            for source_vertex in range(vertex_count):
                source_row = source_vertex * vertex_count
                first_leg = all_pairs[source_row + middle]
                if first_leg >= INFINITY:
                    continue
                for target_vertex in range(vertex_count):
                    second_leg = all_pairs[middle_row + target_vertex]
                    if second_leg < INFINITY:
                        candidate = first_leg + second_leg
                        position = source_row + target_vertex
                        if candidate < all_pairs[position]:
                            all_pairs[position] = candidate
        goal_distances = [all_pairs[vertex * vertex_count + goal] for vertex in range(vertex_count)]
        distance_code, next_code = _encode_snapshot(start, goal, edges, goal_distances)
        checksum += time_index * (distance_code + 1) * (next_code + 1)
    return checksum
