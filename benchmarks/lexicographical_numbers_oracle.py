"""Oracle for the bounded pinned lexicographical_numbers iterator."""

from __future__ import annotations

MAX_NUMBER = 4_096
MAX_INPUT_LENGTH = 1
MAX_PARSEABLE_INPUT_LENGTH = 2
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1
INVALID_RESULT = -1


def expected_result(values: list[int] | tuple[int, ...]) -> int:
    """Return the one-based-position weighted checksum of lexical_order(N)."""
    if (not isinstance(values, (list, tuple)) or len(values) != 1
            or type(values[0]) is not int or not I64_MIN <= values[0] <= I64_MAX
            or not 0 <= values[0] <= MAX_NUMBER):
        return INVALID_RESULT

    maximum = values[0]
    stack = [1]
    checksum = 0
    output_index = 0
    while stack:
        number = stack.pop()
        if number > maximum:
            continue
        output_index += 1
        checksum += output_index * number
        if number % 10 != 9:
            stack.append(number + 1)
        stack.append(number * 10)
    return checksum
