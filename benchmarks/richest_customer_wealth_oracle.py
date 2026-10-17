"""Oracle for the bounded Ruby richest-customer-wealth contract."""

from __future__ import annotations

from collections.abc import Sequence

MAX_ROWS = 32
MAX_COLUMNS = 32
MAX_AMOUNT = 1_000_000
MAX_VALID_INPUT_LENGTH = 2 + MAX_ROWS * MAX_COLUMNS
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
INVALID_RESULT = -1
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1


def expected_result(values: Sequence[int] | None, input_length: int | None = None) -> int:
    """Return the maximum row sum, or -1 for malformed/null input."""
    if values is None:
        return INVALID_RESULT
    if (not isinstance(values, (list, tuple))
            or len(values) > MAX_PARSEABLE_INPUT_LENGTH
            or any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values)):
        return INVALID_RESULT
    if input_length is not None and (type(input_length) is not int or input_length != len(values)):
        return INVALID_RESULT
    if len(values) < 2:
        return INVALID_RESULT
    rows, columns = values[0], values[1]
    if not 1 <= rows <= MAX_ROWS or not 1 <= columns <= MAX_COLUMNS:
        return INVALID_RESULT
    if len(values) != 2 + rows * columns:
        return INVALID_RESULT
    amounts = values[2:]
    if any(not 0 <= amount <= MAX_AMOUNT for amount in amounts):
        return INVALID_RESULT
    return max(sum(amounts[start:start + columns]) for start in range(0, len(amounts), columns))
