"""Fixed 16-register HyperLogLog core with an exact raw estimate."""

from __future__ import annotations

from collections.abc import Sequence
from math import gcd
import struct


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if (type(input_is_null) is not bool or type(output_is_null) is not bool
            or input_is_null or not isinstance(values, (list, tuple))
            or not 1 <= len(values) <= 130
            or input_length is not None and (type(input_length) is not int or input_length != len(values))
            or capacity is not None and (type(capacity) is not int or capacity < 0)
            or any(type(x) is not int or x < -(1 << 63) or x >= (1 << 63) for x in values)):
        return -1, b""
    n = values[0]
    if not 0 <= n <= 128 or len(values) != n + 1 or any(not 0 <= h < (1 << 32) for h in values[1:]):
        return -1, b""
    registers = [0] * 16
    for h in values[1:]:
        bucket = h >> 28
        suffix = h & ((1 << 28) - 1)
        rank = 29 - suffix.bit_length()
        registers[bucket] = max(registers[bucket], rank)
    denominator = 1000 * sum(1 << (29 - rank) for rank in registers)
    numerator = 673 * 256 * (1 << 29)
    divisor = gcd(numerator, denominator)
    words = [numerator // divisor, denominator // divisor, *registers]
    payload = struct.pack("<18q", *words)
    if output_is_null or capacity is not None and capacity < len(payload):
        return -2, b""
    return len(payload), payload
