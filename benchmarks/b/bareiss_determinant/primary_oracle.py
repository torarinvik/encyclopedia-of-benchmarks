"""Pivoted Bareiss fraction-free determinant oracle."""

from __future__ import annotations

MAX_DIMENSION = 8
ENTRY_MIN = -4
ENTRY_MAX = 4
MAX_VALID_INPUT_LENGTH = 65
MAX_PARSEABLE_INPUT_LENGTH = 66
WORKSPACE_BYTES = 4096
INVALID_RESULT = -(1 << 63)


def _parse(values, input_is_null=False, input_length=None):
    if input_is_null or not isinstance(values, (list, tuple)):
        return None
    if (not 1 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return None
    if input_length is not None and (
        type(input_length) is not int or input_length != len(values)
    ):
        return None
    dimension = values[0]
    if not 1 <= dimension <= MAX_DIMENSION or len(values) != 1 + dimension * dimension:
        return None
    if any(value < ENTRY_MIN or value > ENTRY_MAX for value in values[1:]):
        return None
    return dimension, [list(values[1 + row * dimension:1 + (row + 1) * dimension])
                       for row in range(dimension)]


def expected_result(values, input_is_null=False, input_length=None):
    """Return the exact determinant, or INT64_MIN for malformed input."""
    parsed = _parse(values, input_is_null=input_is_null, input_length=input_length)
    if parsed is None:
        return INVALID_RESULT
    dimension, matrix = parsed
    sign = 1
    previous_pivot = 1
    for pivot_index in range(dimension - 1):
        if matrix[pivot_index][pivot_index] == 0:
            replacement = next(
                (row for row in range(pivot_index + 1, dimension)
                 if matrix[row][pivot_index] != 0),
                None,
            )
            if replacement is None:
                return 0
            matrix[pivot_index], matrix[replacement] = matrix[replacement], matrix[pivot_index]
            sign = -sign

        pivot = matrix[pivot_index][pivot_index]
        for row in range(pivot_index + 1, dimension):
            for column in range(pivot_index + 1, dimension):
                numerator = (
                    matrix[row][column] * pivot
                    - matrix[row][pivot_index] * matrix[pivot_index][column]
                )
                matrix[row][column] = numerator // previous_pivot
            matrix[row][pivot_index] = 0
        previous_pivot = pivot

    return sign * matrix[dimension - 1][dimension - 1]
