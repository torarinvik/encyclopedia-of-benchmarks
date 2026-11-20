"""Havel–Hakimi reduction reference for graphical-sequence membership."""

from __future__ import annotations

from .primary_oracle import MAX_PARSEABLE_INPUT_LENGTH, MAX_VERTICES


def expected_result(values, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple))
            or len(values) > MAX_PARSEABLE_INPUT_LENGTH
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return -1
    if input_length is not None and (
            type(input_length) is not int or input_length != len(values)):
        return -1
    if not values or not 0 <= values[0] <= MAX_VERTICES or len(values) != values[0] + 1:
        return -1
    n = values[0]
    degrees = list(values[1:])
    if any(degree < 0 or degree >= n for degree in degrees):
        return -1
    degrees.sort(reverse=True)
    while degrees:
        if degrees[0] == 0:
            return 1
        largest = degrees.pop(0)
        if largest > len(degrees):
            return 0
        for index in range(largest):
            if degrees[index] == 0:
                return 0
            degrees[index] -= 1
        degrees.sort(reverse=True)
    return 1
