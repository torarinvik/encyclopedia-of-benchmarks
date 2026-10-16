"""Independent oracle for full-string wildcard matching with ? and *."""

from __future__ import annotations

MAX_TEXT_LENGTH = 12
MAX_PATTERN_LENGTH = 20
MAX_VALID_INPUT_LENGTH = 2 + MAX_TEXT_LENGTH + MAX_PATTERN_LENGTH
MAX_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1


def expected_result(values: list[int] | tuple[int, ...]) -> int:
    if (not isinstance(values, (list, tuple)) or len(values) < 2
            or len(values) > MAX_INPUT_LENGTH
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return -1
    text_length, pattern_length = values[:2]
    if (not 0 <= text_length <= MAX_TEXT_LENGTH
            or not 0 <= pattern_length <= MAX_PATTERN_LENGTH
            or len(values) != 2 + text_length + pattern_length):
        return -1
    text = values[2:2 + text_length]
    pattern = values[2 + text_length:]
    if (any(not 97 <= value <= 122 for value in text)
            or any(not (97 <= value <= 122 or value in (42, 63)) for value in pattern)):
        return -1

    dp = [[False] * (pattern_length + 1) for _ in range(text_length + 1)]
    dp[0][0] = True
    for column, token in enumerate(pattern, start=1):
        if token == 42:
            dp[0][column] = dp[0][column - 1]
    for row, character in enumerate(text, start=1):
        for column, token in enumerate(pattern, start=1):
            if token == character or token == 63:
                dp[row][column] = dp[row - 1][column - 1]
            elif token == 42:
                dp[row][column] = dp[row - 1][column] or dp[row][column - 1]
    return int(dp[text_length][pattern_length])
