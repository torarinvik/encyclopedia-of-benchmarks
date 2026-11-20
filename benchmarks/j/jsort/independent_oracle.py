"""Built-in ordering reference for bounded signed-i64 JSort inputs."""

from __future__ import annotations

from collections.abc import Sequence

from .primary_oracle import I64_MAX, I64_MIN, MAX_LENGTH


def expected_result(values: Sequence[int]) -> list[int]:
    if (not isinstance(values, (list, tuple)) or len(values) > MAX_LENGTH
            or any(type(value) is not int or not I64_MIN <= value <= I64_MAX
                   for value in values)):
        raise ValueError("JSort oracle expects at most 1024 signed 64-bit integers")
    return sorted(values)
