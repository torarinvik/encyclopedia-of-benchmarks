"""Oracle for the bounded ASCII-string complex-number multiplication source."""

from __future__ import annotations

MAX_TEXT_LENGTH = 64
MAX_INPUT_LENGTH = 130
MAX_COMPONENT = 32_767
MAX_OUTPUT_LENGTH = 24
INVALID_RESULT = -1
INSUFFICIENT_CAPACITY = -2
I64_MIN = -(2**63)
I64_MAX = 2**63 - 1


def _parse_component(data: tuple[int, ...] | list[int]) -> int | None:
    start = 0
    negative = False
    if data and data[0] == 45:
        negative = True
        start = 1
    if start == len(data):
        return None

    magnitude = 0
    for byte in data[start:]:
        if not 48 <= byte <= 57:
            return None
        digit = byte - 48
        if magnitude > (MAX_COMPONENT - digit) // 10:
            return None
        magnitude = magnitude * 10 + digit
    return -magnitude if negative else magnitude


def _parse_complex(data: tuple[int, ...] | list[int]) -> tuple[int, int] | None:
    if not 4 <= len(data) <= MAX_TEXT_LENGTH or data[-1] != 105:
        return None
    separators = [index for index, byte in enumerate(data[:-1]) if byte == 43]
    if len(separators) != 1:
        return None
    separator = separators[0]
    real = _parse_component(data[:separator])
    imaginary = _parse_component(data[separator + 1:-1])
    if real is None or imaginary is None:
        return None
    return real, imaginary


def expected_output(values: tuple[int, ...] | list[int],
                    capacity: int | None = None) -> tuple[int, bytes]:
    """Parse two source-format strings, multiply them, and encode the result."""
    if (not isinstance(values, (tuple, list)) or not 2 <= len(values) <= MAX_INPUT_LENGTH
            or any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values)):
        return INVALID_RESULT, b""
    left_length, right_length = values[:2]
    if not 4 <= left_length <= MAX_TEXT_LENGTH or not 4 <= right_length <= MAX_TEXT_LENGTH:
        return INVALID_RESULT, b""
    if len(values) != 2 + left_length + right_length:
        return INVALID_RESULT, b""
    encoded_inputs = values[2:]
    if any(not 0 <= byte <= 127 for byte in encoded_inputs):
        return INVALID_RESULT, b""
    left = _parse_complex(values[2:2 + left_length])
    right = _parse_complex(values[2 + left_length:])
    if left is None or right is None:
        return INVALID_RESULT, b""

    left_real, left_imaginary = left
    right_real, right_imaginary = right
    real = left_real * right_real - left_imaginary * right_imaginary
    imaginary = left_real * right_imaginary + left_imaginary * right_real
    encoded = f"{real}+{imaginary}i".encode("ascii")
    if capacity is not None and (type(capacity) is not int or capacity < 0):
        return INVALID_RESULT, b""
    if capacity is not None and len(encoded) > capacity:
        return INSUFFICIENT_CAPACITY, b""
    return len(encoded), encoded
