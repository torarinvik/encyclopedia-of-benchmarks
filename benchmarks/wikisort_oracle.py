"""Independent reference helpers for the bounded WikiSort profile."""

from __future__ import annotations


MULTIPLIER = 48271
MODULUS = 2000003
OFFSET = 1000001
MAXIMUM_LENGTH = 2048


def generated_values(length: int) -> list[int]:
    if not 0 <= length <= MAXIMUM_LENGTH:
        raise ValueError("length is outside the bounded workload profile")
    return [((index * MULTIPLIER) % MODULUS) - OFFSET for index in range(length)]


def expected_sorted(values: list[int]) -> list[int]:
    return sorted(values)
