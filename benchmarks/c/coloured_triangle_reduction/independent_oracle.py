"""Direct repeated adjacent-pair reduction, independent of Lucas' theorem."""

from __future__ import annotations

from collections.abc import Sequence

MAX_N = 256
MAX_VALID_INPUT_LENGTH = MAX_N + 1
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
INVALID_RESULT = -1


def _decode(values: Sequence[int] | None, input_is_null: bool,
            input_length: int | None) -> list[int] | None:
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple))
            or not 2 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return None
    if input_length is not None and (
            type(input_length) is not int or input_length != len(values)):
        return None
    n = values[0]
    if not 1 <= n <= MAX_N or len(values) != n + 1:
        return None
    row = list(values[1:])
    if any(color not in (0, 1, 2) for color in row):
        return None
    return row


def expected_result(values: Sequence[int] | None, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    row = _decode(values, input_is_null, input_length)
    if row is None:
        return INVALID_RESULT
    while len(row) > 1:
        row = [(-(row[index] + row[index + 1])) % 3
               for index in range(len(row) - 1)]
    return row[0]
