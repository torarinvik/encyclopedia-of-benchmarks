"""Independent oracle for the bounded C miroir byte-reversal contract."""

from __future__ import annotations

from collections.abc import Sequence

MAX_BYTE_LENGTH = 256
MAX_PARSEABLE_INPUT_LENGTH = MAX_BYTE_LENGTH + 1
INVALID_RESULT = -1
INSUFFICIENT_OUTPUT_CAPACITY = -2
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1


def expected_output(
    values: Sequence[int],
    capacity: int | None = None,
    output_is_null: bool = False,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> tuple[int, bytes]:
    """Return the ABI status and NUL-terminated reversed bytes."""
    if input_length is None:
        declared_length = len(values) if isinstance(values, (list, tuple)) else -1
    elif type(input_length) is int and input_length >= 0:
        declared_length = input_length
    else:
        return INVALID_RESULT, b""
    if (not isinstance(values, (list, tuple))
            or len(values) > MAX_PARSEABLE_INPUT_LENGTH
            or any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values)
            or type(input_is_null) is not bool
            or (input_is_null and (len(values) != 0 or not 1 <= declared_length <= MAX_PARSEABLE_INPUT_LENGTH))
            or (not input_is_null and declared_length != len(values))
            or declared_length > MAX_PARSEABLE_INPUT_LENGTH):
        return INVALID_RESULT, b""
    if input_is_null or not values:
        return INVALID_RESULT, b""

    byte_length = values[0]
    if not 0 <= byte_length <= MAX_BYTE_LENGTH or len(values) != byte_length + 1:
        return INVALID_RESULT, b""
    payload = values[1:]
    if any(not 1 <= byte <= 127 for byte in payload):
        return INVALID_RESULT, b""
    if type(output_is_null) is not bool or (capacity is not None and (type(capacity) is not int or capacity < 0)):
        return INVALID_RESULT, b""
    if output_is_null or (capacity is not None and capacity < byte_length + 1):
        return INSUFFICIENT_OUTPUT_CAPACITY, b""
    result = bytes(reversed(payload)) + b"\0"
    return byte_length, result
