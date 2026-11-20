"""Interpolation-table/linear-probing reference for bounded byte-key inputs."""

from __future__ import annotations

from collections.abc import Sequence

MAX_LENGTH = 1024
MIN_KEY = 0
MAX_KEY = 255


def expected_result(values: Sequence[int]) -> list[int]:
    if (not isinstance(values, (list, tuple)) or len(values) > MAX_LENGTH
            or any(type(value) is not int or not MIN_KEY <= value <= MAX_KEY
                   for value in values)):
        raise ValueError("linear probing sort expects at most 1024 byte-valued keys")
    count = len(values)
    if count < 2:
        return list(values)
    main_slots = 256 * (count + 1) + 1
    slots = [0] * (main_slots + count)
    minimum = min(values)
    maximum = max(values)
    span = maximum - minimum
    for value in values:
        home = 0 if span == 0 else (value - minimum) * (main_slots - 1) // span
        while slots[home] != 0:
            home += 1
        slots[home] = value + 1
    result = [value - 1 for value in slots if value != 0]
    if len(result) != count:
        raise AssertionError("linear probing table did not preserve every key")
    return result
