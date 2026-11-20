"""Deterministic bounded Misra--Gries/Vizing fan edge-coloring reference."""

from __future__ import annotations

from collections.abc import Sequence

MAX_VERTICES = 6
MAX_EDGES = 6
MAX_VALID_INPUT_LENGTH = 14
MAX_PARSEABLE_INPUT_LENGTH = 15
SIGNATURE_BASE = 8 ** 6
MAX_RESULT = 1_760_109
INVALID_RESULT = -1


def _parse(values: Sequence[int] | None, input_is_null: bool,
           input_length: int | None) -> tuple[int, list[tuple[int, int]]] | None:
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple))
            or len(values) < 2 or len(values) > MAX_PARSEABLE_INPUT_LENGTH
            or any(type(value) is not int or value < -(1 << 63) or value >= (1 << 63)
                   for value in values)):
        return None
    declared = len(values) if input_length is None else input_length
    if type(declared) is not int or declared != len(values):
        return None
    vertices, edge_count = values[:2]
    if not 1 <= vertices <= MAX_VERTICES or not 0 <= edge_count <= MAX_EDGES:
        return None
    if len(values) != 2 + 2 * edge_count:
        return None
    edges: list[tuple[int, int]] = []
    seen: set[tuple[int, int]] = set()
    for index in range(edge_count):
        left, right = values[2 + 2 * index:4 + 2 * index]
        if left < 0 or right < 0 or left >= vertices or right >= vertices or left == right:
            return None
        edge = (left, right) if left < right else (right, left)
        if edge in seen:
            return None
        seen.add(edge)
        edges.append(edge)
    return vertices, edges


def _color(vertices: int, edges: list[tuple[int, int]]) -> tuple[int, list[int]]:
    degree = [0] * vertices
    edge_at = [[-1] * vertices for _ in range(vertices)]
    incident: list[list[int]] = [[] for _ in range(vertices)]
    for edge_id, (left, right) in enumerate(edges):
        degree[left] += 1
        degree[right] += 1
        edge_at[left][right] = edge_at[right][left] = edge_id
        incident[left].append(edge_id)
        incident[right].append(edge_id)
    palette_size = max(degree, default=0) + 1 if edges else 0
    colors = [-1] * len(edges)

    def free(vertex: int, color: int) -> bool:
        return all(colors[edge_id] != color for edge_id in incident[vertex])

    for edge_id, (center, first_leaf) in enumerate(edges):
        fan = [first_leaf]
        while True:
            tail = fan[-1]
            added = False
            for neighbor in range(vertices):
                candidate_edge = edge_at[center][neighbor]
                if (candidate_edge < 0 or colors[candidate_edge] < 0
                        or neighbor in fan
                        or not free(tail, colors[candidate_edge])):
                    continue
                fan.append(neighbor)
                added = True
                break
            if not added:
                break

        color_c = next(color for color in range(palette_size) if free(center, color))
        color_d = next(color for color in range(palette_size) if free(fan[-1], color))

        # Save the unique maximal alternating path before flipping its colors.
        path: list[int] = []
        current = center
        wanted = color_d
        visited = {center}
        while True:
            path_edge = -1
            for candidate_edge in incident[current]:
                if colors[candidate_edge] == wanted:
                    path_edge = candidate_edge
                    break
            if path_edge < 0:
                break
            left, right = edges[path_edge]
            nxt = right if current == left else left
            if nxt in visited:
                break
            visited.add(nxt)
            path.append(path_edge)
            current = nxt
            wanted = color_c if wanted == color_d else color_d
        for path_edge in path:
            colors[path_edge] = color_c if colors[path_edge] == color_d else color_d

        prefix_end = next(index for index, vertex in enumerate(fan)
                          if free(vertex, color_d))
        shifted = [colors[edge_at[center][fan[index + 1]]]
                   for index in range(prefix_end)]
        for index, shifted_color in enumerate(shifted):
            colors[edge_at[center][fan[index]]] = shifted_color
        colors[edge_at[center][fan[prefix_end]]] = color_d

    return palette_size, colors


def expected_result(values: Sequence[int] | None, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    """Return palette/signature encoding, or -1 for invalid input."""
    frame = _parse(values, input_is_null, input_length)
    if frame is None:
        return INVALID_RESULT
    vertices, edges = frame
    palette_size, colors = _color(vertices, edges)
    signature = sum(color * (8 ** index) for index, color in enumerate(colors))
    return palette_size * SIGNATURE_BASE + signature
