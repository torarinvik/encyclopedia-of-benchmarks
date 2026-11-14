"""Register-by-register reference using exact rational arithmetic."""

from __future__ import annotations

from collections.abc import Sequence
from fractions import Fraction
import struct


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if (type(input_is_null) is not bool or type(output_is_null) is not bool
            or input_is_null or not isinstance(values, (tuple, list))
            or not 1 <= len(values) <= 130
            or input_length is not None and (type(input_length) is not int or input_length != len(values))
            or capacity is not None and (type(capacity) is not int or capacity < 0)
            or any(type(x) is not int or x < -(1 << 63) or x >= (1 << 63) for x in values)):
        return -1, b""
    count = values[0]
    if (not 0 <= count <= 128 or len(values) != count + 1
            or any(h < 0 or h >= 1 << 32 for h in values[1:])):
        return -1, b""
    ranks = []
    for bucket in range(16):
        best = 0
        for value in values[1:]:
            if value // (1 << 28) != bucket:
                continue
            rank = 1
            for bit in range(27, -1, -1):
                if value & (1 << bit):
                    break
                rank += 1
            best = max(best, rank)
        ranks.append(best)
    estimate = Fraction(673 * 256, 1000) / sum(Fraction(1, 1 << rank) for rank in ranks)
    payload = struct.pack("<18q", estimate.numerator, estimate.denominator, *ranks)
    if output_is_null or capacity is not None and capacity < len(payload):
        return -2, b""
    return len(payload), payload
