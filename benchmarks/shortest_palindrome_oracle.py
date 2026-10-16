"""Independent oracle for the bounded shortest-palindrome contract."""

from __future__ import annotations

MAX_VALID_INPUT_LENGTH = 64
MAX_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_OUTPUT_LENGTH = 2 * MAX_VALID_INPUT_LENGTH - 1
MIN_PRINTABLE_ASCII = 32
MAX_PRINTABLE_ASCII = 126
INVALID_RESULT = -1
INSUFFICIENT_CAPACITY_RESULT = -2


def expected_output(values: list[int], capacity: int | None = None) -> tuple[int, bytes]:
    if (not isinstance(values, list) or len(values) > MAX_VALID_INPUT_LENGTH
            or any(type(value) is not int or not -(2**63) <= value < 2**63
                   or not MIN_PRINTABLE_ASCII <= value <= MAX_PRINTABLE_ASCII
                   for value in values)):
        return INVALID_RESULT, b""
    if capacity is not None and (type(capacity) is not int or capacity < 0):
        return INVALID_RESULT, b""
    if not values:
        return 0, b""

    prefix_length = len(values)
    while prefix_length > 0:
        prefix = values[:prefix_length]
        if prefix == prefix[::-1]:
            break
        prefix_length -= 1

    output = bytes(reversed(values[prefix_length:])) + bytes(values)
    if capacity is not None and capacity < len(output):
        return INSUFFICIENT_CAPACITY_RESULT, b""
    return len(output), output
