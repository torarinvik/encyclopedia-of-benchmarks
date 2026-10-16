"""Reference oracles for simple signed-i64 scalar sequence lookups."""

from __future__ import annotations

I64_MIN = -(2**63)
I64_MAX = 2**63 - 1
MAX_CUBES_SEQUENCE_INDEX = 2_097_151


def all_ones_sequence(value: int) -> int:
    return 1 if type(value) is int and 0 <= value <= I64_MAX else -1


def all_twos_sequence(value: int) -> int:
    return 2 if type(value) is int and 0 <= value <= I64_MAX else -1


def all_threes_sequence(value: int) -> int:
    return 3 if type(value) is int and 0 <= value <= I64_MAX else -1


def cubes_sequence(value: int) -> int:
    if type(value) is not int or not 0 <= value <= MAX_CUBES_SEQUENCE_INDEX:
        return -1
    return value**3
