"""Reference augmenting-path solver for graphic/partition matroid intersection."""

from __future__ import annotations

from collections.abc import Sequence

MAX_VERTICES = 10
MAX_EDGES = 20
MAX_COLORS = 8
MAX_VALID_INPUT_LENGTH = 3 + MAX_COLORS + 3 * MAX_EDGES
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_WORKSPACE_BYTES = 440
INVALID_RESULT = -1


def _decode(values: Sequence[int] | None, input_is_null: bool,
            input_length: int | None):
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple))
            or not 4 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
            or any(type(word) is not int or not -(1 << 63) <= word < (1 << 63)
                   for word in values)):
        return None
    if input_length is not None and (
            type(input_length) is not int or input_length != len(values)):
        return None
    vertices, edge_count, color_count = values[:3]
    if (not 1 <= vertices <= MAX_VERTICES
            or not 0 <= edge_count <= MAX_EDGES
            or not 1 <= color_count <= MAX_COLORS
            or len(values) != 3 + color_count + 3 * edge_count):
        return None
    capacities = values[3:3 + color_count]
    if any(not 0 <= capacity <= MAX_EDGES for capacity in capacities):
        return None
    edges: list[tuple[int, int, int]] = []
    offset = 3 + color_count
    for edge_id in range(edge_count):
        u, v, color = values[offset + 3 * edge_id:offset + 3 * edge_id + 3]
        if not 0 <= u < vertices or not 0 <= v < vertices or not 0 <= color < color_count:
            return None
        edges.append((u, v, color))
    return vertices, edge_count, color_count, capacities, edges


def _is_forest(vertices: int, edges: Sequence[tuple[int, int, int]],
               chosen: Sequence[bool], removed: int = -1, added: int = -1) -> bool:
    parent = list(range(vertices))
    for edge_id, (u, v, _) in enumerate(edges):
        selected = edge_id == added or (chosen[edge_id] and edge_id != removed)
        if not selected:
            continue
        a, b = u, v
        while parent[a] != a:
            a = parent[a]
        while parent[b] != b:
            b = parent[b]
        if a == b:
            return False
        parent[b] = a
    return True


def _within_quotas(color_count: int, capacities: Sequence[int],
                   edges: Sequence[tuple[int, int, int]], chosen: Sequence[bool],
                   removed: int = -1, added: int = -1) -> bool:
    counts = [0] * color_count
    for edge_id, (_, _, color) in enumerate(edges):
        selected = edge_id == added or (chosen[edge_id] and edge_id != removed)
        if selected:
            counts[color] += 1
            if counts[color] > capacities[color]:
                return False
    return True


def expected_result(values: Sequence[int] | None, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    parsed = _decode(values, input_is_null, input_length)
    if parsed is None:
        return INVALID_RESULT
    vertices, edge_count, color_count, capacities, edges = parsed
    chosen = [False] * edge_count

    while True:
        predecessor = [-2] * edge_count
        queue: list[int] = []
        for edge_id in range(edge_count):
            if not chosen[edge_id] and _is_forest(vertices, edges, chosen, added=edge_id):
                predecessor[edge_id] = -1
                queue.append(edge_id)

        terminal = -1
        head = 0
        while head < len(queue) and terminal < 0:
            current = queue[head]
            head += 1
            if not chosen[current]:
                if _within_quotas(color_count, capacities, edges, chosen, added=current):
                    terminal = current
                    break
                for inside in range(edge_count):
                    if chosen[inside] and predecessor[inside] == -2 and _within_quotas(
                            color_count, capacities, edges, chosen,
                            removed=inside, added=current):
                        predecessor[inside] = current
                        queue.append(inside)
            else:
                for outside in range(edge_count):
                    if not chosen[outside] and predecessor[outside] == -2 and _is_forest(
                            vertices, edges, chosen, removed=current, added=outside):
                        predecessor[outside] = current
                        queue.append(outside)

        if terminal < 0:
            break
        node = terminal
        while node >= 0:
            chosen[node] = not chosen[node]
            node = predecessor[node]

    return sum(chosen)
