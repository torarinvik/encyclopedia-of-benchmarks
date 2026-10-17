"""Independent oracle for bounded unsigned modulo."""

from __future__ import annotations

from collections.abc import Sequence

I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1
UINT32_MAX = (1 << 32) - 1
MAX_VALID_INPUT_VALUES = 2
MAX_PARSEABLE_INPUT_VALUES = 5
INVALID_RESULT = -1


def expected_result(values: Sequence[int], input_is_null: bool = False) -> int:
    """Return ``a % b`` for a valid bounded frame, otherwise ``-1``."""
    if type(input_is_null) is not bool:
        return INVALID_RESULT
    if input_is_null:
        return INVALID_RESULT
    if (
        not isinstance(values, (list, tuple))
        or len(values) > MAX_PARSEABLE_INPUT_VALUES
        or any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values)
        or len(values) != MAX_VALID_INPUT_VALUES
    ):
        return INVALID_RESULT

    a, b = values
    if not 0 <= a <= UINT32_MAX or not 1 <= b <= UINT32_MAX:
        return INVALID_RESULT
    return a % b
