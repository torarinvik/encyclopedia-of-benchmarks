"""Oracle for the pinned Ruby implementation's frequency-quotient behavior."""

from __future__ import annotations

MAX_STRING_COUNT = 16
MAX_STRING_LENGTH = 64
MAX_TOTAL_CHARACTERS = 512
MAX_INPUT_LENGTH = 1 + MAX_STRING_COUNT * (1 + MAX_STRING_LENGTH)
MAX_OUTPUT_LENGTH = 64


def expected_output(values: list[int], capacity: int | None = None) -> tuple[int, bytes]:
    if (not isinstance(values, list) or not values or len(values) > MAX_INPUT_LENGTH
            or any(type(value) is not int or not -(2**63) <= value < 2**63 for value in values)):
        return -1, b""
    string_count = values[0]
    if not 0 <= string_count <= MAX_STRING_COUNT:
        return -1, b""

    offset = 1
    counts = [0] * 26
    total_characters = 0
    for _ in range(string_count):
        if offset >= len(values):
            return -1, b""
        length = values[offset]
        offset += 1
        if not 0 <= length <= MAX_STRING_LENGTH or offset + length > len(values):
            return -1, b""
        for value in values[offset:offset + length]:
            if not 97 <= value <= 122:
                return -1, b""
            counts[value - 97] += 1
        total_characters += length
        if total_characters > MAX_TOTAL_CHARACTERS:
            return -1, b""
        offset += length
    if offset != len(values):
        return -1, b""

    output = b"" if string_count == 0 else b"".join(
        bytes((letter + 97,)) * (count // string_count)
        for letter, count in enumerate(counts)
    )
    if len(output) > MAX_OUTPUT_LENGTH:
        return -1, b""
    if capacity is not None and (type(capacity) is not int or capacity < 0):
        return -1, b""
    if capacity is not None and len(output) > capacity:
        return -2, b""
    return len(output), output
