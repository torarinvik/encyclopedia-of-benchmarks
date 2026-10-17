"""Oracle for bounded addition in the pinned decimal large_number class."""

from __future__ import annotations

MAX_DIGITS = 64
MAX_VALID_INPUT_LENGTH = 2 + 2 * MAX_DIGITS
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_OUTPUT_BYTES = MAX_DIGITS + 1
INVALID_RESULT = -1
OUTPUT_ERROR = -2
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1


def _decode(values: tuple[int, ...] | list[int]):
    if (not isinstance(values, (tuple, list))
            or not 2 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
            or any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values)):
        return None

    left_length, right_length = values[:2]
    if not 1 <= left_length <= MAX_DIGITS or not 1 <= right_length <= MAX_DIGITS:
        return None
    if len(values) != 2 + left_length + right_length:
        return None

    left_digits = values[2 : 2 + left_length]
    right_digits = values[2 + left_length :]
    if any(not ord("0") <= digit <= ord("9") for digit in left_digits + right_digits):
        return None
    if left_length > 1 and left_digits[0] == ord("0"):
        return None
    if right_length > 1 and right_digits[0] == ord("0"):
        return None
    return left_digits, right_digits


def expected_output(
    values: tuple[int, ...] | list[int] | None,
    output_capacity: int | None = None,
    output_is_null: bool = False,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> tuple[int, bytes]:
    """Return canonical ASCII decimal sum bytes, or the documented ABI error."""
    if type(output_is_null) is not bool or type(input_is_null) is not bool:
        return INVALID_RESULT, b""
    if output_capacity is not None and (type(output_capacity) is not int or output_capacity < 0):
        return INVALID_RESULT, b""
    if input_length is not None and (type(input_length) is not int or input_length < 0):
        return INVALID_RESULT, b""
    if input_is_null or values is None or not isinstance(values, (tuple, list)):
        return INVALID_RESULT, b""
    if input_length is not None and input_length != len(values):
        return INVALID_RESULT, b""

    decoded = _decode(values)
    if decoded is None:
        return INVALID_RESULT, b""
    left_digits, right_digits = decoded
    left = int(bytes(left_digits).decode("ascii"))
    right = int(bytes(right_digits).decode("ascii"))
    output = str(left + right).encode("ascii")

    if output_is_null or (output_capacity is not None and output_capacity < len(output)):
        return OUTPUT_ERROR, b""
    return len(output), output
