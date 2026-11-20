"""Built-in ordering reference for bounded byte-valued linear probing sort."""

from __future__ import annotations

from collections.abc import Sequence

from .primary_oracle import MAX_KEY, MAX_LENGTH, MIN_KEY


def expected_result(values: Sequence[int]) -> list[int]:
    if (not isinstance(values, (list, tuple)) or len(values) > MAX_LENGTH
            or any(type(value) is not int or not MIN_KEY <= value <= MAX_KEY
                   for value in values)):
        raise ValueError("linear probing sort expects at most 1024 byte-valued keys")
    return sorted(values)
