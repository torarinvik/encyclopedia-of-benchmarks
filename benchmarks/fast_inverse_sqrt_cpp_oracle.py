"""Reference the pinned C++ double-precision fast inverse-square-root routine."""

from __future__ import annotations

import math
import struct

MIN_VALUE = 1e-6
MAX_VALUE = 1e6
INVALID_RESULT = -1.0
MAGIC = 0x5FE6EB50C7B537A9


def expected_result(value: float) -> float:
    """Return the C++ `Fast_InvSqrt<double, 2>` result for one input."""
    if not math.isfinite(value) or not MIN_VALUE <= value <= MAX_VALUE:
        return INVALID_RESULT

    y = value
    x2 = y * 0.5
    bits = struct.unpack("=q", struct.pack("=d", y))[0]
    bits = MAGIC - (bits >> 1)
    y = struct.unpack("=d", struct.pack("=q", bits))[0]

    y = y * (1.5 - (x2 * y * y))
    y = y * (1.5 - (x2 * y * y))
    return y
