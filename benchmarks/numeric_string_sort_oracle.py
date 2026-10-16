"""Oracle for the bounded nonnegative decimal-string numeric sort."""

from __future__ import annotations

MAX_ITEM_COUNT = 64
MAX_TOKEN_LENGTH = 32
MAX_INPUT_LENGTH = 1 + MAX_ITEM_COUNT * (1 + MAX_TOKEN_LENGTH)
MAX_PARSEABLE_INPUT_LENGTH = MAX_INPUT_LENGTH + 1
MAX_OUTPUT_LENGTH = MAX_ITEM_COUNT * MAX_TOKEN_LENGTH + MAX_ITEM_COUNT - 1
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1


def expected_output(values: list[int], capacity: int | None = None) -> tuple[int, bytes]:
    if (not isinstance(values, list) or not 1 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
            or any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values)):
        return -1, b""
    count = values[0]
    if not 0 <= count <= MAX_ITEM_COUNT:
        return -1, b""

    cursor = 1
    tokens: list[bytes] = []
    normalized: dict[bytes, bytes] = {}
    for _ in range(count):
        if cursor >= len(values):
            return -1, b""
        token_length = values[cursor]
        cursor += 1
        if (not 1 <= token_length <= MAX_TOKEN_LENGTH
                or token_length > len(values) - cursor):
            return -1, b""
        raw = values[cursor:cursor + token_length]
        if any(not 48 <= value <= 57 for value in raw):
            return -1, b""
        token = bytes(raw)
        key = token.lstrip(b"0")
        previous = normalized.get(key)
        if previous is not None and previous != token:
            return -1, b""
        normalized[key] = token
        tokens.append(token)
        cursor += token_length
    if cursor != len(values):
        return -1, b""

    tokens.sort(key=lambda token: (len(token.lstrip(b"0")), token.lstrip(b"0")))
    output = b" ".join(tokens)
    if capacity is not None and (type(capacity) is not int or capacity < 0):
        return -1, b""
    if capacity is not None and capacity < len(output):
        return -2, b""
    return len(output), output
