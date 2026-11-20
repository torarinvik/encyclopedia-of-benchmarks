"""Deterministic bounded edge-incidence face reconstruction replay."""

from __future__ import annotations

from collections.abc import Sequence

MIN_VERTICES = 3
MAX_VERTICES = 8
MAX_EDGES = 28
MAX_CANDIDATES = 56
MAX_VALID_INPUT_LENGTH = 58
MAX_PARSEABLE_INPUT_LENGTH = 59
MAX_OUTPUT_BYTES = 1360
WORKSPACE_BYTES = 8192
INVALID_RESULT = -1
OUTPUT_ERROR = -2
_I64_MIN = -(1 << 63)
_I64_MAX = (1 << 63) - 1


def _decode(values: Sequence[int] | None, input_is_null: bool,
            input_length: int | None) -> tuple[int, list[tuple[int, int]]] | None:
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple))
            or not 2 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
            or any(type(value) is not int or not _I64_MIN <= value <= _I64_MAX
                   for value in values)):
        return None
    if input_length is not None and (
            type(input_length) is not int or input_length != len(values)):
        return None
    vertex_count, edge_count = values[0], values[1]
    if not MIN_VERTICES <= vertex_count <= MAX_VERTICES:
        return None
    if not 0 <= edge_count <= min(MAX_EDGES, vertex_count * (vertex_count - 1) // 2):
        return None
    if len(values) != 2 + 2 * edge_count:
        return None
    edges: list[tuple[int, int]] = []
    seen: set[tuple[int, int]] = set()
    for offset in range(2, len(values), 2):
        left, right = values[offset], values[offset + 1]
        if not (0 <= left < vertex_count and 0 <= right < vertex_count) or left == right:
            return None
        edge = (left, right) if left < right else (right, left)
        if edge in seen:
            return None
        seen.add(edge)
        edges.append(edge)
    return vertex_count, edges


def _run(vertex_count: int, edges: list[tuple[int, int]]) -> tuple[int, ...]:
    edge_index = {edge: index for index, edge in enumerate(edges)}
    vertex_degree = [0] * vertex_count
    for left, right in edges:
        vertex_degree[left] += 1
        vertex_degree[right] += 1

    triangles: list[tuple[tuple[int, int, int], tuple[int, int, int]]] = []
    incidence = [0] * len(edges)
    for a in range(vertex_count):
        for b in range(a + 1, vertex_count):
            for c in range(b + 1, vertex_count):
                ab = edge_index.get((a, b))
                ac = edge_index.get((a, c))
                bc = edge_index.get((b, c))
                if ab is not None and ac is not None and bc is not None:
                    triangle = (a, b, c)
                    triangle_edges = (ab, ac, bc)
                    triangles.append((triangle, triangle_edges))
                    for edge_id in triangle_edges:
                        incidence[edge_id] += 1

    active = [True] * len(triangles)
    used = [0] * len(edges)
    selected: list[tuple[int, int, int]] = []
    fallback_used = False

    def select(index: int) -> None:
        active[index] = False
        triangle, triangle_edges = triangles[index]
        selected.append(triangle)
        for edge_id in triangle_edges:
            incidence[edge_id] -= 1
            used[edge_id] += 1
        saturated = {edge_id for edge_id in triangle_edges if used[edge_id] == 2}
        if saturated:
            for other, (_, other_edges) in enumerate(triangles):
                if active[other] and any(edge_id in saturated for edge_id in other_edges):
                    active[other] = False
                    for edge_id in other_edges:
                        incidence[edge_id] -= 1

    while True:
        chosen = next((index for index, (triangle, _) in enumerate(triangles)
                       if active[index]
                       and any(vertex_degree[vertex] == 3 for vertex in triangle)), None)
        if chosen is not None:
            select(chosen)
            continue

        forced = {edge_id for edge_id, degree in enumerate(incidence)
                  if degree > 0 and degree == 2 - used[edge_id]}
        chosen = next((index for index, (_, triangle_edges) in enumerate(triangles)
                       if active[index] and any(edge_id in forced for edge_id in triangle_edges)), None)
        if chosen is not None:
            select(chosen)
            continue

        chosen = None
        best_score = MAX_CANDIDATES * 3 + 1
        for index, (_, triangle_edges) in enumerate(triangles):
            if active[index]:
                score = sum(incidence[edge_id] for edge_id in triangle_edges)
                if score < best_score:
                    chosen = index
                    best_score = score
        if chosen is None:
            break
        fallback_used = True
        select(chosen)

    complete = bool(edges) and all(count == 2 for count in used)
    status = (0 if complete else 2) + (1 if fallback_used else 0)
    words = [status, len(selected)]
    for triangle in selected:
        words.extend(triangle)
    return tuple(words)


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or capacity is not None and (type(capacity) is not int or capacity < 0)
            or input_length is not None and (
                type(input_length) is not int
                or not 0 <= input_length <= MAX_PARSEABLE_INPUT_LENGTH)
            or input_is_null and values not in (None, [], ())
            or not input_is_null and values is not None and input_length is not None
            and (not isinstance(values, (list, tuple)) or input_length != len(values))):
        return INVALID_RESULT, b""
    if input_is_null or values is None:
        return INVALID_RESULT, b""
    decoded = _decode(values, input_is_null, input_length)
    if decoded is None:
        return INVALID_RESULT, b""
    words = _run(*decoded)
    staged = b"".join(word.to_bytes(8, "little", signed=True) for word in words)
    if output_is_null or capacity is not None and capacity < len(staged):
        return OUTPUT_ERROR, b""
    return len(staged), staged
