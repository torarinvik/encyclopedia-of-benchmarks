"""Lindström–Gessel–Viennot count for ordered paths in a blocked grid."""

from __future__ import annotations

from itertools import permutations

I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1
MAX_HEIGHT = 5
MAX_WIDTH = 5
MAX_PATHS = 3
MAX_VALID_INPUT_LENGTH = 10
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_GRID_MASK = (1 << (MAX_HEIGHT * MAX_WIDTH)) - 1
MAX_RESULT = 343_000
WORKSPACE_BYTES = 4096


def _decode(values, input_is_null: bool, input_length: int | None):
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (tuple, list))
            or len(values) > MAX_PARSEABLE_INPUT_LENGTH
            or any(type(value) is not int or not I64_MIN <= value <= I64_MAX
                   for value in values)):
        return None
    if input_length is not None and (
            type(input_length) is not int or input_length != len(values)):
        return None
    if len(values) < 4:
        return None
    height, width, path_count, blocked = values[:4]
    if (not 1 <= height <= MAX_HEIGHT or not 2 <= width <= MAX_WIDTH
            or not 1 <= path_count <= min(MAX_PATHS, height)
            or not 0 <= blocked < (1 << (height * width))):
        return None
    if len(values) != 4 + 2 * path_count:
        return None
    sources = list(values[4:4 + path_count])
    sinks = list(values[4 + path_count:])
    if (any(not 0 <= row < height for row in sources + sinks)
            or any(sources[index] >= sources[index + 1]
                   for index in range(path_count - 1))
            or any(sinks[index] >= sinks[index + 1]
                   for index in range(path_count - 1))
            or any(sources[index] > sinks[index]
                   for index in range(path_count))):
        return None
    for row in sources:
        if blocked >> (row * width) & 1:
            return None
    for row in sinks:
        if blocked >> (row * width + width - 1) & 1:
            return None
    return height, width, path_count, blocked, sources, sinks


def _path_matrix(height: int, width: int, path_count: int, blocked: int,
                 sources: list[int], sinks: list[int]) -> list[list[int]]:
    matrix = [[0] * path_count for _ in range(path_count)]
    for source_index, source_row in enumerate(sources):
        ways = [[0] * width for _ in range(height)]
        ways[source_row][0] = 1
        for row in range(height):
            for column in range(width):
                if blocked >> (row * width + column) & 1:
                    ways[row][column] = 0
                    continue
                count = ways[row][column]
                if not count:
                    continue
                if column + 1 < width and not (blocked >> (row * width + column + 1) & 1):
                    ways[row][column + 1] += count
                if row + 1 < height and not (blocked >> ((row + 1) * width + column) & 1):
                    ways[row + 1][column] += count
        for sink_index, sink_row in enumerate(sinks):
            matrix[source_index][sink_index] = ways[sink_row][width - 1]
    return matrix


def _determinant(matrix: list[list[int]]) -> int:
    size = len(matrix)
    result = 0
    for permutation in permutations(range(size)):
        inversions = sum(
            permutation[left] > permutation[right]
            for left in range(size)
            for right in range(left + 1, size)
        )
        term = 1
        for row, column in enumerate(permutation):
            term *= matrix[row][column]
        result += -term if inversions % 2 else term
    return result


def expected_result(values, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    decoded = _decode(values, input_is_null, input_length)
    if decoded is None:
        return -1
    height, width, path_count, blocked, sources, sinks = decoded
    matrix = _path_matrix(height, width, path_count, blocked, sources, sinks)
    return _determinant(matrix)
