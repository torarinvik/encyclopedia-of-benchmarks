"""Independent subsequence-mask enumeration oracle for bounded inputs."""

from __future__ import annotations

from collections.abc import Sequence

MODULUS = 1_000_000_007
MAX_LENGTH = 20
ALPHABET_SIZE = 4
MAX_VALID_INPUT_LENGTH = MAX_LENGTH + 1
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1


def expected_result(values: Sequence[int] | None) -> int:
    if not isinstance(values, (list, tuple)) or not 1 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH:
        return -1
    if any(type(value) is not int or not -(1 << 63) <= value < (1 << 63) for value in values):
        return -1
    n = values[0]
    if type(n) is not int or not 0 <= n <= MAX_LENGTH or len(values) != n + 1:
        return -1
    symbols = values[1:]
    if any(not 0 <= symbol < ALPHABET_SIZE for symbol in symbols):
        return -1
    unique: set[tuple[int, ...]] = set()
    for mask in range(1, 1 << n):
        candidate = tuple(symbols[i] for i in range(n) if mask & (1 << i))
        if candidate == candidate[::-1]:
            unique.add(candidate)
    return len(unique) % MODULUS
