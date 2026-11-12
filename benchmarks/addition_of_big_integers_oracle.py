"""Digit-array oracle for bounded signed decimal integer addition."""

from __future__ import annotations

MAX_DIGITS = 32
MAX_TEXT_LENGTH = MAX_DIGITS + 1
MAX_INPUT_LENGTH = 2 + 2 * MAX_TEXT_LENGTH
MAX_OUTPUT_BYTES = MAX_DIGITS + 2
INVALID_RESULT = -1
INSUFFICIENT_CAPACITY = -2
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1


def _decode_operand(text: tuple[int, ...]) -> tuple[bool, tuple[int, ...]] | None:
    if not 1 <= len(text) <= MAX_TEXT_LENGTH:
        return None
    negative = text[0] == 45
    start = 1 if negative else 0
    if start == len(text):
        return None
    digits = text[start:]
    if len(digits) > MAX_DIGITS or any(not 48 <= byte <= 57 for byte in digits):
        return None
    if len(digits) > 1 and digits[0] == 48:
        return None
    if negative and digits == (48,):
        return None
    return negative, tuple(byte - 48 for byte in digits)


def _compare(left: tuple[int, ...], right: tuple[int, ...]) -> int:
    if len(left) != len(right):
        return 1 if len(left) > len(right) else -1
    for a, b in zip(left, right):
        if a != b:
            return 1 if a > b else -1
    return 0


def _magnitude_sum(left: tuple[int, ...], right: tuple[int, ...]) -> list[int]:
    output: list[int] = []
    carry = 0
    for offset in range(max(len(left), len(right))):
        a = left[-1 - offset] if offset < len(left) else 0
        b = right[-1 - offset] if offset < len(right) else 0
        total = a + b + carry
        output.append(total % 10)
        carry = total // 10
    if carry:
        output.append(carry)
    return output


def _magnitude_difference(larger: tuple[int, ...], smaller: tuple[int, ...]) -> list[int]:
    output: list[int] = []
    borrow = 0
    for offset in range(len(larger)):
        a = larger[-1 - offset]
        b = smaller[-1 - offset] if offset < len(smaller) else 0
        digit = a - b - borrow
        borrow = 1 if digit < 0 else 0
        output.append(digit + 10 if digit < 0 else digit)
    while len(output) > 1 and output[-1] == 0:
        output.pop()
    return output


def expected_output(
    values: list[int] | tuple[int, ...],
    output_capacity: int | None = None,
    output_is_null: bool = False,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> tuple[int, bytes]:
    """Return the digit-array result as ``(status, canonical_ascii_bytes)``."""
    if input_is_null or not isinstance(values, (list, tuple)):
        return INVALID_RESULT, b""
    if (len(values) < 4 or len(values) > MAX_INPUT_LENGTH
            or any(type(value) is not int or not I64_MIN <= value <= I64_MAX
                   for value in values)):
        return INVALID_RESULT, b""
    if input_length is not None and (type(input_length) is not int or input_length != len(values)):
        return INVALID_RESULT, b""

    length_a, length_b = values[:2]
    if (type(length_a) is not int or type(length_b) is not int
            or not 1 <= length_a <= MAX_TEXT_LENGTH
            or not 1 <= length_b <= MAX_TEXT_LENGTH
            or len(values) != 2 + length_a + length_b):
        return INVALID_RESULT, b""
    text_a = tuple(values[2:2 + length_a])
    text_b = tuple(values[2 + length_a:])
    if any(not 0 <= byte <= 127 for byte in text_a + text_b):
        return INVALID_RESULT, b""
    decoded_a = _decode_operand(text_a)
    decoded_b = _decode_operand(text_b)
    if decoded_a is None or decoded_b is None:
        return INVALID_RESULT, b""
    negative_a, digits_a = decoded_a
    negative_b, digits_b = decoded_b

    if negative_a == negative_b:
        magnitude = _magnitude_sum(digits_a, digits_b)
        negative = negative_a
    else:
        comparison = _compare(digits_a, digits_b)
        if comparison == 0:
            magnitude, negative = [0], False
        elif comparison > 0:
            magnitude = _magnitude_difference(digits_a, digits_b)
            negative = negative_a
        else:
            magnitude = _magnitude_difference(digits_b, digits_a)
            negative = negative_b

    encoded = bytes(([45] if negative else []) + [48 + digit for digit in reversed(magnitude)])
    if len(encoded) > MAX_OUTPUT_BYTES:
        return INVALID_RESULT, b""
    if type(output_is_null) is not bool:
        return INSUFFICIENT_CAPACITY, b""
    if output_capacity is not None and (
        type(output_capacity) is not int or output_capacity < 0
    ):
        return INSUFFICIENT_CAPACITY, b""
    if output_is_null or (output_capacity is not None and len(encoded) > output_capacity):
        return INSUFFICIENT_CAPACITY, b""
    return len(encoded), encoded
