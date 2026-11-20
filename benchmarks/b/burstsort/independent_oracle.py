"""Independent host-sort reference for the bounded Burstsort contract."""

from __future__ import annotations

from collections.abc import Sequence

MAX_STRINGS = 16
MAX_STRING_LENGTH = 8
MAX_INPUT_LENGTH = 146
MAX_RESULT = 53_124_864


def expected_result(values: Sequence[int] | None, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple))
            or not 1 <= len(values) <= MAX_INPUT_LENGTH
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)
            or input_length is not None
            and (type(input_length) is not int or input_length != len(values))):
        return -1
    count = values[0]
    if not 0 <= count <= MAX_STRINGS:
        return -1
    offset = 1
    strings: list[bytes] = []
    for _ in range(count):
        if offset >= len(values):
            return -1
        length = values[offset]
        offset += 1
        if not 0 <= length <= MAX_STRING_LENGTH or offset + length > len(values):
            return -1
        content = values[offset:offset + length]
        if any(not 0 <= byte <= 3 for byte in content):
            return -1
        strings.append(bytes(content))
        offset += length
    if offset != len(values):
        return -1

    total = 0
    for rank, value in enumerate(sorted(strings), start=1):
        key = 0
        for index, byte in enumerate(value):
            key += (byte + 1) * 5 ** (MAX_STRING_LENGTH - 1 - index)
        total += rank * key
    return total if total <= MAX_RESULT else -1
