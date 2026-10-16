"""Independent oracle for the bounded recursive Fisher-Yates shuffle."""

from __future__ import annotations

import struct

MAX_VALUES = 64
MAX_INPUT_LENGTH = MAX_VALUES + 2  # one excess value is parseable as malformed input
MODULUS = 2_147_483_647
MIN_SEED = 1
MAX_SEED = MODULUS - 1
MIN_VALUE = -(1 << 31)
MAX_VALUE = (1 << 31) - 1


def expected_output(values: list[int] | tuple[int, ...]) -> tuple[int, bytes]:
    if (not isinstance(values, (list, tuple)) or not 1 <= len(values) <= MAX_INPUT_LENGTH
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return -1, b""

    seed, *items = values
    if (not MIN_SEED <= seed <= MAX_SEED or len(items) > MAX_VALUES
            or any(not MIN_VALUE <= value <= MAX_VALUE for value in items)):
        return -1, b""

    state = seed

    def shuffle(items_to_process: int) -> None:
        nonlocal state
        if items_to_process <= 0:
            return
        shuffle(items_to_process - 1)
        state = state * 48_271 % MODULUS
        other = state % (items_to_process + 1)
        items[items_to_process], items[other] = items[other], items[items_to_process]

    shuffle(len(items) - 1)
    output = b"".join(struct.pack("<i", value) for value in items)
    return len(items), output
