"""Library-sort reference for weak-heapsort fixtures."""

from __future__ import annotations

from .primary_oracle import (
    I64_MAX,
    I64_MIN,
    MAX_PARSEABLE_INPUT_LENGTH,
    MAX_VALUES,
    MAX_VALUE,
    MIN_VALUE,
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
    if not values or not 0 <= values[0] <= MAX_VALUES:
        return -1
    size = values[0]
    if len(values) != size + 1:
        return -1
    data = list(values[1:])
    if any(not MIN_VALUE <= value <= MAX_VALUE for value in data):
        return -1
    data.sort()
    return sum((index + 1) * (value - MIN_VALUE + 1)
               for index, value in enumerate(data))
