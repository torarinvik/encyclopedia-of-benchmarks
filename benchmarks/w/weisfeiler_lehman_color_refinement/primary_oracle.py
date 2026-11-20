"""Canonical 1-WL refinement using sorted neighborhood signatures."""

from __future__ import annotations

MAX_VERTICES = 8
MAX_VALID_INPUT_LENGTH = 9
MAX_PARSEABLE_INPUT_LENGTH = 10
WORKSPACE_BYTES = 4096
INVALID_RESULT = -1
COLOR_BASE = 9


def _parse(values, input_is_null=False, input_length=None):
    if input_is_null or not isinstance(values, (list, tuple)):
        return None
    if (not 1 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
            or any(type(value) is not int or value < 0 or value >= (1 << 63)
                   for value in values)):
        return None
    if input_length is not None and (
        type(input_length) is not int or input_length != len(values)
    ):
        return None
    n = values[0]
    if not 0 <= n <= MAX_VERTICES or len(values) != n + 1:
        return None
    limit = (1 << n) - 1
    adjacency = values[1:]
    if any(mask & ~limit for mask in adjacency):
        return None
    for vertex, mask in enumerate(adjacency):
        if mask & (1 << vertex):
            return None
        for neighbor in range(n):
            if bool(mask & (1 << neighbor)) != bool(adjacency[neighbor] & (1 << vertex)):
                return None
    return n, adjacency


def _canonical_colors(signatures):
    unique = sorted(set(signatures))
    rank = {signature: color for color, signature in enumerate(unique)}
    return [rank[signature] for signature in signatures], len(unique)


def expected_result(values, input_is_null=False, input_length=None):
    """Pack stable vertex colors in base 9, with vertex 0 as digit 0."""
    parsed = _parse(values, input_is_null=input_is_null, input_length=input_length)
    if parsed is None:
        return INVALID_RESULT
    n, adjacency = parsed
    if n == 0:
        return 0

    colors = [mask.bit_count() for mask in adjacency]
    class_count = len(set(colors))

    while True:
        signatures = []
        for vertex, mask in enumerate(adjacency):
            neighborhood = tuple(sorted(
                colors[neighbor] for neighbor in range(n)
                if mask & (1 << neighbor)
            ))
            signatures.append((colors[vertex], neighborhood))
        new_colors, new_class_count = _canonical_colors(signatures)
        colors = new_colors
        if new_class_count == class_count:
            break
        class_count = new_class_count

    packed = 0
    place = 1
    for color in colors:
        packed += color * place
        place *= COLOR_BASE
    return packed
