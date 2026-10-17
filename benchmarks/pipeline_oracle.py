"""Independent oracle for the bounded left-to-right pipeline benchmark."""

from __future__ import annotations

from collections.abc import Sequence

INVALID_RESULT = -1
MAX_STAGES = 32
MAX_INPUT_LENGTH = 2 + 2 * MAX_STAGES
MAX_PARSEABLE_INPUT_LENGTH = MAX_INPUT_LENGTH + 2
MIN_VALUE = 0
MAX_VALUE = 2
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1


def expected_result(
    values: Sequence[int] | None,
    input_length: int | None = None,
) -> int:
    """Apply encoded stages in order, or return -1 for malformed input."""
    if values is None or not isinstance(values, (list, tuple)):
        return INVALID_RESULT
    if input_length is not None and (
        type(input_length) is not int or input_length != len(values)
    ):
        return INVALID_RESULT
    if not 2 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH:
        return INVALID_RESULT
    if any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values):
        return INVALID_RESULT

    initial, stage_count = values[0], values[1]
    if not MIN_VALUE <= initial <= MAX_VALUE or not 1 <= stage_count <= MAX_STAGES:
        return INVALID_RESULT
    if len(values) != 2 + 2 * stage_count:
        return INVALID_RESULT

    result = initial
    for index in range(stage_count):
        operation = values[2 + 2 * index]
        argument = values[3 + 2 * index]
        if operation not in (0, 1) or not MIN_VALUE <= argument <= MAX_VALUE:
            return INVALID_RESULT
        if operation == 0:
            result += argument
        else:
            result *= argument
    return result
