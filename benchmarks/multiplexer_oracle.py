"""Independent bounded oracle for the two-to-one Boolean multiplexer."""

from __future__ import annotations

from collections.abc import Sequence

I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1
MAX_INPUT_LENGTH = 3
MAX_PARSEABLE_INPUT_LENGTH = 4
INVALID_RESULT = -1


def expected_result(values: Sequence[int]) -> int:
    """Return the selected bit, or the invalid-input sentinel."""
    if (
        not isinstance(values, (list, tuple))
        or len(values) != MAX_INPUT_LENGTH
        or any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values)
    ):
        return INVALID_RESULT
    input0, input1, select = values
    if any(value not in (0, 1) for value in (input0, input1, select)):
        return INVALID_RESULT
    return input1 if select == 1 else input0
