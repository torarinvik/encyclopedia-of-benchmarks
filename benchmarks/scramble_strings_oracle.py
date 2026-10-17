"""Oracle for the bounded pinned JavaScript scramble-string recursion."""

from __future__ import annotations

from collections.abc import Sequence
from functools import lru_cache

MAX_LENGTH = 8
MAX_INPUT_LENGTH = 2 * MAX_LENGTH + 1
MAX_PARSEABLE_INPUT_LENGTH = MAX_INPUT_LENGTH + 2
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1
INVALID_RESULT = -1


def _is_scramble(first: str, second: str) -> bool:
    @lru_cache(maxsize=None)
    def helper(left: str, right: str) -> bool:
        if left == right:
            return True

        counts = [0] * 26
        for a, b in zip(left, right):
            counts[ord(a) - ord("a")] += 1
            counts[ord(b) - ord("a")] -= 1
        if any(counts):
            return False

        for split in range(1, len(left)):
            if (helper(left[:split], right[:split])
                    and helper(left[split:], right[split:])):
                return True
            if (helper(left[:split], right[len(right) - split:])
                    and helper(left[split:], right[:len(right) - split])):
                return True
        return False

    return helper(first, second)


def expected_result(
    values: Sequence[int],
    input_is_null: bool = False,
    input_length: int | None = None,
) -> int:
    if input_length is None:
        declared_length = len(values) if isinstance(values, (list, tuple)) else -1
    elif type(input_length) is int and input_length >= 0:
        declared_length = input_length
    else:
        return INVALID_RESULT
    if (not isinstance(values, (list, tuple))
            or len(values) > MAX_PARSEABLE_INPUT_LENGTH
            or any(type(value) is not int or not I64_MIN <= value <= I64_MAX
                   for value in values)
            or type(input_is_null) is not bool
            or (input_is_null and (len(values) != 0
                                   or not 1 <= declared_length <= MAX_PARSEABLE_INPUT_LENGTH))
            or (not input_is_null and declared_length != len(values))
            or declared_length > MAX_PARSEABLE_INPUT_LENGTH):
        return INVALID_RESULT
    if input_is_null or declared_length < 1:
        return INVALID_RESULT

    length = values[0]
    if (length < 0 or length > MAX_LENGTH
            or len(values) != 2 * length + 1):
        return INVALID_RESULT
    characters = values[1:]
    if any(not 97 <= value <= 122 for value in characters):
        return INVALID_RESULT

    first = "".join(chr(value) for value in characters[:length])
    second = "".join(chr(value) for value in characters[length:])
    return int(_is_scramble(first, second))
