"""Direct point-by-point evaluation oracle for affine range composition."""

from __future__ import annotations

import struct
from collections.abc import Sequence

from .primary_oracle import (
    I64_MAX,
    I64_MIN,
    MAX_INPUT_LENGTH,
    MAX_N,
    MAX_OUTPUT_BYTES,
    MAX_Q,
    MODULUS,
)


def _read(values: Sequence[int] | None, input_length: int | None,
          input_is_null: bool) -> tuple[list[tuple[int, int]], list[tuple[int, int]]] | None:
    if type(input_is_null) is not bool or input_is_null:
        return None
    if not isinstance(values, (tuple, list)) or len(values) < 2 or len(values) > MAX_INPUT_LENGTH:
        return None
    if any(type(value) is not int or value < I64_MIN or value > I64_MAX for value in values):
        return None
    declared = len(values) if input_length is None else input_length
    if type(declared) is not int or declared != len(values):
        return None
    n, q = values[0], values[1]
    if type(n) is not int or type(q) is not int or not 1 <= n <= MAX_N or not 1 <= q <= MAX_Q:
        return None
    if len(values) != 2 + 2 * n + 2 * q:
        return None
    maps: list[tuple[int, int]] = []
    offset = 2
    for _ in range(n):
        multiplier, addend = values[offset], values[offset + 1]
        if multiplier < 0 or multiplier >= MODULUS or addend < 0 or addend >= MODULUS:
            return None
        maps.append((multiplier, addend))
        offset += 2
    ranges: list[tuple[int, int]] = []
    for _ in range(q):
        lo, hi = values[offset], values[offset + 1]
        if lo < 0 or lo > hi or hi >= n:
            return None
        ranges.append((lo, hi))
        offset += 2
    return maps, ranges


def _simulate(maps: list[tuple[int, int]], lo: int, hi: int) -> tuple[int, int]:
    # Evaluating at 0 gives the addend; evaluating at 1 then subtracting it gives the multiplier.
    value_at_zero = 0
    value_at_one = 1
    for index in range(lo, hi + 1):
        multiplier, addend = maps[index]
        value_at_zero = (multiplier * value_at_zero + addend) % MODULUS
        value_at_one = (multiplier * value_at_one + addend) % MODULUS
    return (value_at_one - value_at_zero) % MODULUS, value_at_zero


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    parsed = _read(values, input_length, input_is_null)
    if parsed is None:
        return -1, b""
    maps, ranges = parsed
    encoded = b"".join(struct.pack("<q", item)
                        for lo, hi in ranges for item in _simulate(maps, lo, hi))
    actual_capacity = MAX_OUTPUT_BYTES if capacity is None else capacity
    if (type(output_is_null) is not bool or type(actual_capacity) is not int
            or actual_capacity < 0):
        return -2, b""
    if output_is_null or len(encoded) > actual_capacity:
        return -2, b""
    return len(encoded), encoded
