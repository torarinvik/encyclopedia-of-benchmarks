"""Independent 1-WL reference by explicit partition-block refinement."""

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
    adjacency = values[1:]
    allowed = (1 << n) - 1
    if any(mask & ~allowed for mask in adjacency):
        return None
    for vertex in range(n):
        if adjacency[vertex] & (1 << vertex):
            return None
        for neighbor in range(vertex + 1, n):
            if bool(adjacency[vertex] & (1 << neighbor)) != bool(
                adjacency[neighbor] & (1 << vertex)
            ):
                return None
    return n, adjacency


def expected_result(values, input_is_null=False, input_length=None):
    """Split degree classes by neighbor-color multisets until stable."""
    parsed = _parse(values, input_is_null=input_is_null, input_length=input_length)
    if parsed is None:
        return INVALID_RESULT
    n, adjacency = parsed
    if n == 0:
        return 0

    degree_groups = {}
    for vertex, mask in enumerate(adjacency):
        degree_groups.setdefault(mask.bit_count(), []).append(vertex)
    blocks = [degree_groups[degree] for degree in sorted(degree_groups)]

    while True:
        old_colors = [0] * n
        for color, block in enumerate(blocks):
            for vertex in block:
                old_colors[vertex] = color

        refined_blocks = []
        for block in blocks:
            signatures = []
            for vertex in block:
                neighbor_colors = tuple(sorted(
                    old_colors[neighbor] for neighbor in range(n)
                    if adjacency[vertex] & (1 << neighbor)
                ))
                signatures.append((neighbor_colors, vertex))
            signatures.sort()

            previous_signature = None
            current_block = []
            for signature, vertex in signatures:
                if previous_signature is not None and signature != previous_signature:
                    refined_blocks.append(current_block)
                    current_block = []
                current_block.append(vertex)
                previous_signature = signature
            if current_block:
                refined_blocks.append(current_block)

        if len(refined_blocks) == len(blocks):
            blocks = refined_blocks
            break
        blocks = refined_blocks

    colors = [0] * n
    for color, block in enumerate(blocks):
        for vertex in block:
            colors[vertex] = color
    packed = 0
    place = 1
    for color in colors:
        packed += color * place
        place *= COLOR_BASE
    return packed
