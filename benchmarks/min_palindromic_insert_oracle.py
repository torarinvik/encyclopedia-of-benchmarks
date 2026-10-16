"""Independent bounded dynamic-programming oracle for palindrome insertion."""

from __future__ import annotations

import struct
from collections.abc import Sequence

MIN_LENGTH = 1
MAX_LENGTH = 256
MAX_INPUT_LENGTH = 1 + MAX_LENGTH
MAX_PARSEABLE_INPUT_LENGTH = MAX_INPUT_LENGTH
MAX_OUTPUT_BYTES = 16 + 2 * MAX_LENGTH - 1
INVALID_RESULT = -1
CAPACITY_ERROR = -2
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1


def expected_output(values: Sequence[int], capacity: int | None = None) -> tuple[int, bytes]:
    if (not isinstance(values, (list, tuple)) or not 1 <= len(values) <= MAX_INPUT_LENGTH
            or any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values)):
        return INVALID_RESULT, b""
    n = values[0]
    if not MIN_LENGTH <= n <= MAX_LENGTH or len(values) != n + 1:
        return INVALID_RESULT, b""
    chars = list(values[1:])
    if any(not 32 <= byte <= 126 for byte in chars):
        return INVALID_RESULT, b""

    dp = [[0] * n for _ in range(n)]
    for span in range(2, n + 1):
        for left in range(n - span + 1):
            right = left + span - 1
            if chars[left] == chars[right]:
                dp[left][right] = dp[left + 1][right - 1] if span > 2 else 0
            else:
                dp[left][right] = min(dp[left + 1][right], dp[left][right - 1]) + 1

    palindrome_length = n + dp[0][n - 1]
    palindrome = bytearray(palindrome_length)
    left, right = 0, n - 1
    out_left, out_right = 0, palindrome_length - 1
    while left <= right:
        if chars[left] == chars[right]:
            palindrome[out_left] = chars[left]
            palindrome[out_right] = chars[right]
            left += 1
            right -= 1
        elif dp[left + 1][right] < dp[left][right - 1]:
            palindrome[out_left] = chars[left]
            palindrome[out_right] = chars[left]
            left += 1
        else:
            # The pinned R reconstruction takes the right endpoint on ties.
            palindrome[out_left] = chars[right]
            palindrome[out_right] = chars[right]
            right -= 1
        out_left += 1
        out_right -= 1

    output = struct.pack("<qq", dp[0][n - 1], palindrome_length) + bytes(palindrome)
    if capacity is not None and (type(capacity) is not int or capacity < len(output)):
        return CAPACITY_ERROR, b""
    return len(output), output


def expected_result(values: Sequence[int], capacity: int | None = None) -> tuple[int, bytes]:
    return expected_output(values, capacity)
