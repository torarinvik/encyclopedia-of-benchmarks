"""Recompute every active triangle incidence for each heuristic transition."""

from __future__ import annotations

from collections.abc import Sequence

MIN_VERTICES = 3
MAX_VERTICES = 8
MAX_EDGES = 28
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
    vertices, edge_count = values[0], values[1]
    if not MIN_VERTICES <= vertices <= MAX_VERTICES:
        return None
    if not 0 <= edge_count <= min(MAX_EDGES, vertices * (vertices - 1) // 2):
        return None
    if len(values) != 2 + 2 * edge_count:
        return None
    edges: list[tuple[int, int]] = []
    edge_set: set[tuple[int, int]] = set()
    for offset in range(2, len(values), 2):
        x, y = values[offset], values[offset + 1]
        if not 0 <= x < vertices or not 0 <= y < vertices or x == y:
            return None
        edge = (x, y) if x < y else (y, x)
        if edge in edge_set:
            return None
        edge_set.add(edge)
        edges.append(edge)
    return vertices, edges


def _edge_triples(vertices: int, edge_set: set[tuple[int, int]]) -> list[tuple[int, int, int]]:
    triangles: list[tuple[int, int, int]] = []
    for a in range(vertices):
        for b in range(a + 1, vertices):
            for c in range(b + 1, vertices):
                if (a, b) in edge_set and (a, c) in edge_set and (b, c) in edge_set:
                    triangles.append((a, b, c))
    return triangles


def _replay(vertices: int, edges: list[tuple[int, int]]) -> tuple[int, ...]:
    edge_set = set(edges)
    degree = [0] * vertices
    for x, y in edges:
        degree[x] += 1
        degree[y] += 1
    candidates = _edge_triples(vertices, edge_set)
    active = [True] * len(candidates)
    used = {edge: 0 for edge in edges}
    selected: list[tuple[int, int, int]] = []

    def candidate_edges(triangle: tuple[int, int, int]) -> tuple[tuple[int, int], ...]:
        a, b, c = triangle
        return (a, b), (a, c), (b, c)

    def incidences() -> dict[tuple[int, int], int]:
        totals = {edge: 0 for edge in edges}
        for index, triangle in enumerate(candidates):
            if active[index]:
                for edge in candidate_edges(triangle):
                    totals[edge] += 1
        return totals

    def choose(triangle_index: int) -> None:
        triangle = candidates[triangle_index]
        active[triangle_index] = False
        selected.append(triangle)
        saturated: set[tuple[int, int]] = set()
        for edge in candidate_edges(triangle):
            used[edge] += 1
            if used[edge] == 2:
                saturated.add(edge)
        if saturated:
            for index, other in enumerate(candidates):
                if active[index] and any(edge in saturated for edge in candidate_edges(other)):
                    active[index] = False

    fallback_used = False
    while True:
        seed = next((i for i, tri in enumerate(candidates)
                     if active[i] and any(degree[v] == 3 for v in tri)), None)
        if seed is not None:
            choose(seed)
            continue

        current = incidences()
        forced = {edge for edge, amount in current.items()
                  if amount > 0 and amount == 2 - used[edge]}
        forced_candidate = next((i for i, tri in enumerate(candidates)
                                 if active[i] and any(edge in forced for edge in candidate_edges(tri))), None)
        if forced_candidate is not None:
            choose(forced_candidate)
            continue

        next_candidate = None
        next_score = MAX_VERTICES * MAX_VERTICES * 3 + 1
        for i, tri in enumerate(candidates):
            if active[i]:
                score = sum(current[edge] for edge in candidate_edges(tri))
                if score < next_score:
                    next_candidate = i
                    next_score = score
        if next_candidate is None:
            break
        fallback_used = True
        choose(next_candidate)

    is_complete = bool(edges) and all(used[edge] == 2 for edge in edges)
    state = (0 if is_complete else 2) + int(fallback_used)
    result = [state, len(selected)]
    for triangle in selected:
        result.extend(triangle)
    return tuple(result)


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
    words = _replay(*decoded)
    staged = b"".join(word.to_bytes(8, "little", signed=True) for word in words)
    if output_is_null or capacity is not None and capacity < len(staged):
        return OUTPUT_ERROR, b""
    return len(staged), staged
