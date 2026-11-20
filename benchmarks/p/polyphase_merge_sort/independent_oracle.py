"""Insertion-sort reference independent of the run/tape merge schedule."""

from __future__ import annotations

from collections.abc import Sequence

from .primary_oracle import MAX_LENGTH, MIN_I64, MAX_I64


def expected_result(values: Sequence[int]) -> list[int]:
    if (not isinstance(values, (list, tuple)) or len(values) > MAX_LENGTH
            or any(type(value) is not int or not MIN_I64 <= value <= MAX_I64
                   for value in values)):
        raise ValueError("polyphase merge sort expects at most 256 signed 64-bit integers")
    result = list(values)
    for index in range(1, len(result)):
        value = result[index]
        position = index
        while position > 0 and result[position - 1] > value:
            result[position] = result[position - 1]
            position -= 1
        result[position] = value
    return result
