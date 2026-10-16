"""Oracle for the bounded Java reverse-words-in-string contract."""

from __future__ import annotations

MAX_TEXT_LENGTH = 256
MAX_INPUT_LENGTH = MAX_TEXT_LENGTH + 1
MAX_PARSEABLE_INPUT_LENGTH = MAX_INPUT_LENGTH + 1
MAX_OUTPUT_LENGTH = MAX_TEXT_LENGTH
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1
JAVA_REGEX_SPACE = frozenset((9, 10, 11, 12, 13, 32))


def expected_output(values: list[int], capacity: int | None = None) -> tuple[int, bytes]:
    if (not isinstance(values, list) or not 1 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
            or any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values)):
        return -1, b""
    text_length = values[0]
    if not 0 <= text_length <= MAX_TEXT_LENGTH or len(values) != text_length + 1:
        return -1, b""
    text_values = values[1:]
    if any(not 0 <= value <= 127 for value in text_values):
        return -1, b""

    start = 0
    end = text_length
    while start < end and text_values[start] <= 32:
        start += 1
    while end > start and text_values[end - 1] <= 32:
        end -= 1
    tokens: list[bytes] = []
    position = start
    while position < end:
        while position < end and text_values[position] in JAVA_REGEX_SPACE:
            position += 1
        if position == end:
            break
        token_start = position
        while position < end and text_values[position] not in JAVA_REGEX_SPACE:
            position += 1
        tokens.append(bytes(text_values[token_start:position]))
    output = b" ".join(reversed(tokens))

    if capacity is not None and (type(capacity) is not int or capacity < 0):
        return -1, b""
    if capacity is not None and capacity < len(output):
        return -2, b""
    return len(output), output
