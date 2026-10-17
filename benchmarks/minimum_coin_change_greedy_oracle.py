"""Bounded greedy reference oracle for the pinned Python and Rust implementations."""

from __future__ import annotations

import struct

MIN_TARGET = -4096
MAX_TARGET = 4096
MAX_DENOMINATIONS = 32
MIN_DENOMINATION = 1
MAX_DENOMINATION = 4096
MAX_INPUT_VALUES = 2 + MAX_DENOMINATIONS
MAX_OUTPUT_VALUES = 1 + MAX_TARGET
MAX_OUTPUT_BYTES = MAX_OUTPUT_VALUES * 4
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1


def expected_output(
    values: list[int] | tuple[int, ...],
    output_capacity: int = MAX_OUTPUT_BYTES,
    output_is_null: bool = False,
) -> tuple[int, bytes]:
    """Return a count-prefixed i32le vector of selected coins, or an ABI error."""
    if (
        not isinstance(values, (list, tuple))
        or not 2 <= len(values) <= MAX_INPUT_VALUES
        or any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values)
    ):
        return -1, b""

    target, denomination_count = values[:2]
    if not MIN_TARGET <= target <= MAX_TARGET:
        return -1, b""
    if not 0 <= denomination_count <= MAX_DENOMINATIONS:
        return -1, b""
    if len(values) != 2 + denomination_count:
        return -1, b""

    denominations = values[2:]
    previous = 0
    for denomination in denominations:
        if not MIN_DENOMINATION <= denomination <= MAX_DENOMINATION or denomination <= previous:
            return -1, b""
        previous = denomination

    chosen: list[int] = []
    if target > 0:
        remaining = target
        for denomination in reversed(denominations):
            while remaining >= denomination:
                remaining -= denomination
                chosen.append(denomination)

    if type(output_capacity) is not int or output_capacity < 0:
        return -1, b""
    needed = (1 + len(chosen)) * 4
    if output_is_null or output_capacity < needed:
        return -2, b""

    output_values = (len(chosen), *chosen)
    output = struct.pack("<" + "i" * len(output_values), *output_values)
    return len(output), output
