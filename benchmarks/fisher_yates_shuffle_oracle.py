"""Independent deterministic oracle for the seeded Fisher–Yates benchmark."""
from __future__ import annotations

MAX_LENGTH = 1024
MODULUS = 2_147_483_647


def expected_output(values: list[int], algorithm: str = "fisher_yates_shuffle") -> tuple[int, bytes]:
    if algorithm != "fisher_yates_shuffle" or not 1 <= len(values) <= MAX_LENGTH + 1:
        return -1, b""
    seed, *items = values
    if not 1 <= seed < MODULUS or any(value < -(1 << 31) or value >= (1 << 31) for value in items):
        return -1, b""
    state = seed
    for remaining in range(len(items), 1, -1):
        state = state * 48_271 % MODULUS
        other = state % remaining
        items[remaining - 1], items[other] = items[other], items[remaining - 1]
    return len(items), b"".join((value & 0xFFFF_FFFF).to_bytes(4, "little") for value in items)
