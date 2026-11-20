"""Comparison-sort reference for the American-flag string profile."""

from __future__ import annotations

from .primary_oracle import I64_MAX, I64_MIN, MAX_PARSEABLE_INPUT_LENGTH, MAX_STRING_LENGTH, MAX_STRINGS


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
    if not values or not 0 <= values[0] <= MAX_STRINGS:
        return None
    count = values[0]
    cursor = 1
    strings: list[tuple[int, ...]] = []
    for _ in range(count):
        if cursor >= len(values):
            return None
        length = values[cursor]
        cursor += 1
        if not 0 <= length <= MAX_STRING_LENGTH or cursor + length > len(values):
            return None
        string = tuple(values[cursor:cursor + length])
        if any(not 0 <= byte <= 255 for byte in string):
            return None
        strings.append(string)
        cursor += length
    if cursor != len(values):
        return None
    return strings


def expected_result(values, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    strings = _decode(values, input_is_null, input_length)
    if strings is None:
        return -1
    checksum = 0
    for rank, string in enumerate(sorted(strings), start=1):
        contribution = len(string) + 1 + sum(byte + 1 for byte in string)
        checksum += rank * contribution
    return checksum
