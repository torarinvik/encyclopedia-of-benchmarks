"""Independent direct-scan oracle for 2D rectangle frequency-square queries."""

from __future__ import annotations

from collections.abc import Sequence

INVALID_RESULT = -1
MAX_N = 8
MAX_QUERIES = 32
MAX_VALID_INPUT_LENGTH = 2 + MAX_N * MAX_N + 4 * MAX_QUERIES
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1


def expected_result(values: Sequence[int] | None, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    if type(input_is_null) is not bool or input_is_null or not isinstance(values, (list, tuple)):
        return INVALID_RESULT
    length = len(values) if input_length is None else input_length
    if (type(length) is not int or length < 2 or length > MAX_PARSEABLE_INPUT_LENGTH
            or length != len(values)):
        return INVALID_RESULT
    if any(type(value) is not int or not -(1 << 63) <= value < (1 << 63) for value in values):
        return INVALID_RESULT
    size, query_count = values[:2]
    if not 1 <= size <= MAX_N or not 0 <= query_count <= MAX_QUERIES:
        return INVALID_RESULT
    matrix_end = 2 + size * size
    if length != matrix_end + 4 * query_count:
        return INVALID_RESULT
    matrix = values[2:matrix_end]
    if any(not 0 <= value <= 7 for value in matrix):
        return INVALID_RESULT
    answer = 0
    for index in range(query_count):
        top, left, bottom, right = values[matrix_end + 4 * index:matrix_end + 4 * index + 4]
        if not (0 <= top <= bottom < size and 0 <= left <= right < size):
            return INVALID_RESULT
        frequencies = [0] * 8
        for row in range(top, bottom + 1):
            for column in range(left, right + 1):
                frequencies[matrix[row * size + column]] += 1
        answer += (index + 1) * sum(count * count for count in frequencies)
    return answer
