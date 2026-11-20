"""Direct substring-set oracle, independent of rolling hashes."""

from __future__ import annotations

from .primary_oracle import (
    I64_MAX, I64_MIN, MAX_PARSEABLE_INPUT_LENGTH, MAX_TEXT_LENGTH,
)


def expected_result(values, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (tuple, list))
            or len(values) > MAX_PARSEABLE_INPUT_LENGTH
            or any(type(value) is not int or not I64_MIN <= value <= I64_MAX
                   for value in values)):
        return -1
    if input_length is not None and (
            type(input_length) is not int or input_length != len(values)):
        return -1
    if not values:
        return -1
    size = values[0]
    if not 0 <= size <= MAX_TEXT_LENGTH or len(values) != size + 1:
        return -1
    symbols = values[1:]
    if any(not 0 <= symbol <= 255 for symbol in symbols):
        return -1
    unique = set()
    for start in range(size):
        for end in range(start + 1, size + 1):
            unique.add(tuple(symbols[start:end]))
    return len(unique)
