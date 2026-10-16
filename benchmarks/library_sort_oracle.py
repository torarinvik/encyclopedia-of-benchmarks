"""Independent output and checksum oracle for bounded Library Sort inputs."""

from __future__ import annotations

import itertools
import random

MAX_LENGTH = 256
MIN_VALUE = -(1 << 31)
MAX_VALUE = (1 << 31) - 1
U64_MASK = (1 << 64) - 1
FNV_OFFSET_BASIS = 14695981039346656037
FNV_PRIME = 1099511628211


def expected_output(values: list[int] | tuple[int, ...]) -> list[int] | None:
    """Return the sorted values, or None when the input is outside contract."""
    if (not isinstance(values, (list, tuple)) or len(values) > MAX_LENGTH
            or any(type(value) is not int or not MIN_VALUE <= value <= MAX_VALUE
                   for value in values)):
        return None
    return sorted(values)


def expected_checksum(values: list[int] | tuple[int, ...]) -> int | None:
    """Return the sort runner's unsigned 64-bit FNV-1a checksum."""
    ordered = expected_output(values)
    if ordered is None:
        return None
    checksum = FNV_OFFSET_BASIS
    for value in ordered:
        checksum = ((checksum ^ (value & U64_MASK)) * FNV_PRIME) & U64_MASK
    return checksum


def corpus() -> tuple[tuple[int, ...], ...]:
    """Return deterministic small-pattern, boundary, and maximum-size inputs."""
    arrays: set[tuple[int, ...]] = set()
    for length in range(7):
        arrays.update(itertools.product((-1, 0, 1), repeat=length))
    arrays.update({
        (MIN_VALUE,), (MAX_VALUE,),
        (MIN_VALUE, MAX_VALUE), (MAX_VALUE, MIN_VALUE),
        (MIN_VALUE, 0, MAX_VALUE),
        (MAX_VALUE, MIN_VALUE, -1, 0, 1, MAX_VALUE),
        (7,) * MAX_LENGTH,
        tuple(range(-MAX_LENGTH // 2, MAX_LENGTH // 2)),
        tuple(range(MAX_LENGTH // 2 - 1, -MAX_LENGTH // 2 - 1, -1)),
    })
    rng = random.Random(20261016)
    for _ in range(256):
        length = rng.randrange(MAX_LENGTH + 1)
        arrays.add(tuple(rng.randrange(MIN_VALUE, MAX_VALUE + 1) for _ in range(length)))
    return tuple(sorted(arrays, key=lambda values: (len(values), values)))
