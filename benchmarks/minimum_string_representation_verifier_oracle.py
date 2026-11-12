"""Independent direct-rotation oracle for minimum cyclic representation."""

from __future__ import annotations

from collections.abc import Sequence

from minimum_string_representation_oracle import (
    INVALID_RESULT,
    MAX_LENGTH,
)


def expected_result(values: Sequence[int] | None, input_length: int | None = None,
                    input_is_null: bool = False) -> int:
    if type(input_is_null) is not bool:
        return INVALID_RESULT
    if input_length is not None and (type(input_length) is not int or input_length < 0):
        return INVALID_RESULT
    if input_length is not None and input_length > MAX_LENGTH:
        return INVALID_RESULT
    if input_length == 0:
        return 0
    if input_is_null or not isinstance(values, (list, tuple)):
        return INVALID_RESULT
    n = len(values) if input_length is None else input_length
    if n > MAX_LENGTH or n != len(values):
        return INVALID_RESULT
    if any(type(value) is not int or not 0 <= value <= 127 for value in values):
        return INVALID_RESULT
    if n == 0:
        return 0

    best = 0
    for candidate in range(1, n):
        offset = 0
        while offset < n:
            a = values[(candidate + offset) % n]
            b = values[(best + offset) % n]
            if a < b:
                best = candidate
                break
            if a > b:
                break
            offset += 1
        if offset == n and candidate < best:
            best = candidate
    return best


def verify_result(values: Sequence[int] | None, result: int,
                  input_length: int | None = None,
                  input_is_null: bool = False) -> bool:
    return result == expected_result(values, input_length, input_is_null)
