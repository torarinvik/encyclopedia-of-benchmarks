"""Independent direct-cut oracle for undirected edge connectivity."""

from __future__ import annotations

from collections.abc import Sequence

MAX_VERTICES = 10
MAX_EDGES = 45
MAX_VALID_INPUT_LENGTH = 2 + 2 * MAX_EDGES
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
INVALID_RESULT = -1
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1


def _decode(
    values: Sequence[int] | None,
    input_is_null: bool,
    input_length: int | None,
) -> tuple[int, tuple[tuple[int, int], ...]] | None:
    if type(input_is_null) is not bool or input_is_null or not isinstance(values, (list, tuple)):
        return None
    actual_length = len(values)
    if input_length is None:
        input_length = actual_length
    if (
        type(input_length) is not int
        or input_length != actual_length
        or not 2 <= actual_length <= MAX_PARSEABLE_INPUT_LENGTH
        or any(type(value) is not int or value < I64_MIN or value > I64_MAX for value in values)
    ):
        return None
    vertex_count, edge_count = values[0], values[1]
    if not 2 <= vertex_count <= MAX_VERTICES or not 0 <= edge_count <= MAX_EDGES:
        return None
    if actual_length != 2 + 2 * edge_count:
        return None
    edges: list[tuple[int, int]] = []
    seen: set[tuple[int, int]] = set()
    for index in range(edge_count):
        left, right = values[2 + 2 * index], values[3 + 2 * index]
        if not (0 <= left < vertex_count and 0 <= right < vertex_count) or left == right:
            return None
        edge = (left, right) if left < right else (right, left)
        if edge in seen:
            return None
        seen.add(edge)
        edges.append(edge)
    return vertex_count, tuple(edges)


def expected_result(
    values: Sequence[int] | None,
    *,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> int:
    """Enumerate every nontrivial cut and minimize its crossing-edge count."""
    parsed = _decode(values, input_is_null, input_length)
    if parsed is None:
        return INVALID_RESULT
    vertex_count, edges = parsed
    best = len(edges)
    for side in range(1, (1 << vertex_count) - 1):
        crossing = sum(((side >> left) ^ (side >> right)) & 1 for left, right in edges)
        if crossing < best:
            best = crossing
            if best == 0:
                return 0
    return best
