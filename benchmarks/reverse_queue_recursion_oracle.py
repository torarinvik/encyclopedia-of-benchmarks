"""Independent bounded oracle for recursive queue reversal's final byte order."""

from __future__ import annotations

from collections.abc import Sequence

MAX_QUEUE_LENGTH = 32
MAX_VALID_INPUT_LENGTH = MAX_QUEUE_LENGTH + 1
MAX_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_OUTPUT_BYTES = MAX_QUEUE_LENGTH
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1
INVALID_RESULT = -1
OUTPUT_ERROR_RESULT = -2


def expected_output(
    values: Sequence[int] | None,
    output_capacity: int | None = None,
    output_is_null: bool = False,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> tuple[int, bytes]:
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or (output_capacity is not None
                and (type(output_capacity) is not int or output_capacity < 0))
            or (input_length is not None and type(input_length) is not int)):
        return INVALID_RESULT, b""
    if input_is_null:
        if ((values is not None and values != [] and values != ())
                or input_length != 1):
            return INVALID_RESULT, b""
        if output_is_null:
            return OUTPUT_ERROR_RESULT, b""
        return 0, b""
    if values is None:
        return INVALID_RESULT, b""
    if (not isinstance(values, (list, tuple))
            or len(values) < 1
            or len(values) > MAX_INPUT_LENGTH
            or (input_length is not None and input_length != len(values))
            or any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values)):
        return INVALID_RESULT, b""

    queue_length = values[0]
    queue = values[1:]
    if (not 0 <= queue_length <= MAX_QUEUE_LENGTH
            or len(queue) != queue_length
            or any(value < 0 or value > 255 for value in queue)):
        return INVALID_RESULT, b""

    output = bytes(reversed(queue))
    if output_is_null or (output_capacity is not None and output_capacity < len(output)):
        return OUTPUT_ERROR_RESULT, b""
    return len(output), output
