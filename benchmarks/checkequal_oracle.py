"""Independent oracle for the bounded integer-matrix equality benchmark."""

from __future__ import annotations

I64_MIN, I64_MAX = -(2**63), 2**63 - 1
MAX_DIMENSION = 32
MAX_VALID_INPUT_LENGTH = 4 + 2 * MAX_DIMENSION * MAX_DIMENSION
# Keep one extra slot available for a malformed over-length corpus case.
MAX_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1


def expected_result(values: list[int]) -> int:
    """Return 1 for equal matrices, 0 for unequal matrices, and -1 if malformed."""
    if (not isinstance(values, list) or len(values) < 4 or len(values) > MAX_INPUT_LENGTH
            or any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values)):
        return -1

    rows_a, columns_a, rows_b, columns_b = values[:4]
    if any(not 0 <= dimension <= MAX_DIMENSION
           for dimension in (rows_a, columns_a, rows_b, columns_b)):
        return -1

    count_a = rows_a * columns_a
    count_b = rows_b * columns_b
    if len(values) != 4 + count_a + count_b:
        return -1
    if rows_a != rows_b or columns_a != columns_b:
        return 0
    return int(values[4:4 + count_a] == values[4 + count_a:])
