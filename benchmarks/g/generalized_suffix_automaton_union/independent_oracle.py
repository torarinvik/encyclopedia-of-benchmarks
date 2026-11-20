"""Direct set-enumeration reference for generalized distinct substrings."""

from __future__ import annotations

from .primary_oracle import (
    I64_MAX,
    I64_MIN,
    MAX_PARSEABLE_INPUT_LENGTH,
    MAX_STRING_LENGTH,
    MAX_STRINGS,
    MAX_TOTAL_LENGTH,
    MIN_STRINGS,
)


def _decode(values, input_is_null: bool, input_length: int | None):
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (tuple, list))
            or len(values) > MAX_PARSEABLE_INPUT_LENGTH
            or any(type(value) is not int or not I64_MIN <= value <= I64_MAX
                   for value in values)):
        return None
    if input_length is not None and (
            type(input_length) is not int or input_length != len(values)):
        return None
    if not values or not MIN_STRINGS <= values[0] <= MAX_STRINGS:
        return None
    strings = []
    cursor = 1
    total = 0
    for _ in range(values[0]):
        if cursor >= len(values):
            return None
        length = values[cursor]
        cursor += 1
        if not 0 <= length <= MAX_STRING_LENGTH or cursor + length > len(values):
            return None
        current = tuple(values[cursor:cursor + length])
        if any(not 0 <= symbol <= 3 for symbol in current):
            return None
        strings.append(current)
        total += length
        cursor += length
    if cursor != len(values) or total > MAX_TOTAL_LENGTH:
        return None
    return strings


def expected_result(values, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    strings = _decode(values, input_is_null, input_length)
    if strings is None:
        return -1
    substrings: set[tuple[int, ...]] = set()
    for string in strings:
        for start in range(len(string)):
            for end in range(start + 1, len(string) + 1):
                substrings.add(string[start:end])
    return len(substrings)
