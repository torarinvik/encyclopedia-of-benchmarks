"""Bounded oracle for the pinned Python strings.join function."""
from __future__ import annotations

MAX_ITEMS = 32
MAX_SEPARATOR_LENGTH = 32
MAX_ITEM_LENGTH = 64
MAX_INPUT_LENGTH = 2 + MAX_SEPARATOR_LENGTH + MAX_ITEMS * (1 + MAX_ITEM_LENGTH)
MAX_PARSEABLE_LENGTH = MAX_INPUT_LENGTH + 1
MAX_OUTPUT_LENGTH = MAX_ITEMS * MAX_ITEM_LENGTH + (MAX_ITEMS - 1) * MAX_SEPARATOR_LENGTH
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1


def expected_output(values: list[int], capacity: int | None = None) -> tuple[int, bytes]:
    if (not isinstance(values, list) or not 2 <= len(values) <= MAX_PARSEABLE_LENGTH
            or any(type(x) is not int or not I64_MIN <= x <= I64_MAX for x in values)):
        return -1, b""
    separator_length, item_count = values[:2]
    if not 0 <= separator_length <= MAX_SEPARATOR_LENGTH or not 0 <= item_count <= MAX_ITEMS:
        return -1, b""
    if len(values) < 2 + separator_length:
        return -1, b""
    separator = values[2:2 + separator_length]
    if any(not 0 <= b <= 127 for b in separator):
        return -1, b""
    cursor = 2 + separator_length
    items = []
    for _ in range(item_count):
        if cursor >= len(values):
            return -1, b""
        length = values[cursor]
        cursor += 1
        if not 0 <= length <= MAX_ITEM_LENGTH or cursor + length > len(values):
            return -1, b""
        item = values[cursor:cursor + length]
        if any(not 0 <= b <= 127 for b in item):
            return -1, b""
        items.append(bytes(item))
        cursor += length
    if cursor != len(values):
        return -1, b""
    if capacity is not None and (type(capacity) is not int or capacity < 0):
        return -1, b""
    output = bytes(separator).join(items)
    if capacity is not None and capacity < len(output):
        return -2, b""
    return len(output), output
