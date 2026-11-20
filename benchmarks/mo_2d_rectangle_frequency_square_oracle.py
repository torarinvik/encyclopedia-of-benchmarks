"""2D Mo scheduling for weighted rectangle frequency-square queries."""

from __future__ import annotations

from collections.abc import Sequence

MAX_N = 8
MAX_QUERIES = 32
MAX_VALUE = 7
MAX_VALID_INPUT_LENGTH = 2 + MAX_N * MAX_N + 4 * MAX_QUERIES
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
INVALID_RESULT = -1


def _parse(values: Sequence[int] | None, input_is_null: bool,
           input_length: int | None) -> tuple[int, int, list[int], list[tuple[int, int, int, int]]] | None:
    if type(input_is_null) is not bool or input_is_null or not isinstance(values, (list, tuple)):
        return None
    actual_length = len(values) if input_length is None else input_length
    if (type(actual_length) is not int or actual_length < 2
            or actual_length > MAX_PARSEABLE_INPUT_LENGTH or actual_length != len(values)):
        return None
    if any(type(value) is not int or not -(1 << 63) <= value < (1 << 63) for value in values):
        return None
    size, query_count = values[:2]
    if not 1 <= size <= MAX_N or not 0 <= query_count <= MAX_QUERIES:
        return None
    matrix_end = 2 + size * size
    if actual_length != matrix_end + 4 * query_count:
        return None
    matrix = list(values[2:matrix_end])
    if any(not 0 <= value <= MAX_VALUE for value in matrix):
        return None
    queries: list[tuple[int, int, int, int]] = []
    for offset in range(matrix_end, actual_length, 4):
        top, left, bottom, right = values[offset:offset + 4]
        if not (0 <= top <= bottom < size and 0 <= left <= right < size):
            return None
        queries.append((top, left, bottom, right))
    return size, query_count, matrix, queries


def _block_size(size: int, query_count: int) -> int:
    for block in range(size, 0, -1):
        if query_count * block**4 <= size**4:
            return block
    return 1


def expected_result(values: Sequence[int] | None, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    parsed = _parse(values, input_is_null, input_length)
    if parsed is None:
        return INVALID_RESULT
    size, query_count, matrix, queries = parsed
    if query_count == 0:
        return 0

    block = _block_size(size, query_count)
    ordered = sorted(
        enumerate(queries),
        key=lambda item: (
            item[1][0] // block, item[1][1] // block,
            item[1][2] // block, item[1][3] // block,
            *item[1], item[0],
        ),
    )
    frequencies = [0] * (MAX_VALUE + 1)
    frequency_square_sum = 0

    def add(row: int, column: int) -> None:
        nonlocal frequency_square_sum
        value = matrix[row * size + column]
        old_frequency = frequencies[value]
        frequency_square_sum += 2 * old_frequency + 1
        frequencies[value] = old_frequency + 1

    def remove(row: int, column: int) -> None:
        nonlocal frequency_square_sum
        value = matrix[row * size + column]
        old_frequency = frequencies[value]
        frequency_square_sum += 1 - 2 * old_frequency
        frequencies[value] = old_frequency - 1

    original_index, first = ordered[0]
    top, left, bottom, right = first
    for row in range(top, bottom + 1):
        for column in range(left, right + 1):
            add(row, column)
    answer = (original_index + 1) * frequency_square_sum

    for original_index, target in ordered[1:]:
        target_top, target_left, target_bottom, target_right = target
        while top > target_top:
            top -= 1
            for column in range(left, right + 1):
                add(top, column)
        while bottom < target_bottom:
            bottom += 1
            for column in range(left, right + 1):
                add(bottom, column)
        while left > target_left:
            left -= 1
            for row in range(top, bottom + 1):
                add(row, left)
        while right < target_right:
            right += 1
            for row in range(top, bottom + 1):
                add(row, right)
        while top < target_top:
            for column in range(left, right + 1):
                remove(top, column)
            top += 1
        while bottom > target_bottom:
            for column in range(left, right + 1):
                remove(bottom, column)
            bottom -= 1
        while left < target_left:
            for row in range(top, bottom + 1):
                remove(row, left)
            left += 1
        while right > target_right:
            for row in range(top, bottom + 1):
                remove(row, right)
            right -= 1
        answer += (original_index + 1) * frequency_square_sum
    return answer
