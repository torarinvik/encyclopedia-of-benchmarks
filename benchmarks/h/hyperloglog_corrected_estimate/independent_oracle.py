"""High-precision correction reference with independent raw registers."""

from __future__ import annotations

from collections.abc import Sequence
from decimal import Decimal, localcontext
import struct

from h.hyperloglog_raw_estimate.independent_oracle import expected_output as raw_output


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if type(output_is_null) is not bool or capacity is not None and (type(capacity) is not int or capacity < 0):
        return -1, b""
    status, payload = raw_output(values, 144, False, input_is_null, input_length)
    if status < 0:
        return -1, b""
    numerator, denominator, *registers = struct.unpack("<18q", payload)
    with localcontext() as context:
        context.prec = 80
        raw = Decimal(numerator) / Decimal(denominator)
        zeros = registers.count(0)
        universe = Decimal(1 << 32)
        if numerator <= 40 * denominator and zeros:
            estimate = Decimal(16) * (Decimal(16) / Decimal(zeros)).ln()
        elif 30 * numerator <= (1 << 32) * denominator:
            estimate = raw
        elif numerator < (1 << 32) * denominator:
            estimate = -universe * (Decimal(1) - raw / universe).ln()
        else:
            return -3, b""
    if output_is_null or capacity is not None and capacity < 8:
        return -2, b""
    return 8, struct.pack("<d", float(estimate))
