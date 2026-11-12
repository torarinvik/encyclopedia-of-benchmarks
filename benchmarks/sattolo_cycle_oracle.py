"""Independent deterministic oracle for the Sattolo cycle shuffle."""
from __future__ import annotations

MAX_VALUES = 1024
MODULUS = 2_147_483_647
INVALID_RESULT = -1
OUTPUT_ERROR = -2


def expected_output(values: list[int], algorithm: str = "sattolo_cycle") -> tuple[int, bytes]:
    if (algorithm != "sattolo_cycle" or not isinstance(values, list)
            or not 1 <= len(values) <= MAX_VALUES + 1
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return INVALID_RESULT, b""
    seed, *items = values
    if (not 1 <= seed < MODULUS or len(items) > MAX_VALUES
            or any(value < -(1 << 31) or value >= (1 << 31) for value in items)):
        return INVALID_RESULT, b""
    state = seed
    for remaining in range(len(items), 1, -1):
        state = state * 48_271 % MODULUS
        other = state % (remaining - 1)
        items[remaining - 1], items[other] = items[other], items[remaining - 1]
    return len(items), b"".join((value & 0xFFFF_FFFF).to_bytes(4, "little") for value in items)
