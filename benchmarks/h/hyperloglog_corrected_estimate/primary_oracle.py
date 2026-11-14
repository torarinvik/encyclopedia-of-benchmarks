"""Original 32-bit HLL corrections applied to the fixed-register raw core."""

from __future__ import annotations

from collections.abc import Sequence
import math
import struct

from h.hyperloglog_raw_estimate.primary_oracle import expected_output as raw_output


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if type(output_is_null) is not bool or capacity is not None and (type(capacity) is not int or capacity < 0):
        return -1, b""
    status, payload = raw_output(values, 144, False, input_is_null, input_length)
    if status < 0:
        return -1, b""
    numerator, denominator, *registers = struct.unpack("<18q", payload)
    raw = numerator / denominator
    zeroes = registers.count(0)
    if raw <= 40 and zeroes:
        result = 16.0 * math.log(16.0 / zeroes)
    elif raw <= (1 << 32) / 30.0:
        result = raw
    elif raw < 1 << 32:
        result = -(1 << 32) * math.log1p(-raw / (1 << 32))
    else:
        return -3, b""
    if output_is_null or capacity is not None and capacity < 8:
        return -2, b""
    return 8, struct.pack("<d", result)
