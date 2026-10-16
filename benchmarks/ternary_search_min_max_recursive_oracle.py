"""Oracle for the bounded recursive ternary minimum/maximum benchmark."""
from __future__ import annotations

import math
import struct

INVALID_RESULT = -1.0e300
MAX_INPUT_LENGTH = 5
EXACT_INPUT_LENGTH = 4
MAX_RECURSION_DEPTH = 32


def _f32(value: float) -> float:
    return struct.unpack("<f", struct.pack("<f", value))[0]


def _function(mode: int, x: float) -> float:
    x = _f32(x)
    squared = _f32(x * x)
    doubled = _f32(_f32(2.0) * x)
    if mode == 0:
        return _f32(_f32(squared - doubled) + _f32(3.0))
    return _f32(_f32(-squared - doubled) + _f32(3.0))


def _search(mode: int, start: float, end: float, precision: float, depth: int = 0) -> float:
    if abs(_f32(end - start)) >= precision:
        third = _f32(_f32(end - start) / _f32(3.0))
        mid1 = _f32(start + third)
        mid2 = _f32(end - third)
        r1 = _function(mode, mid1)
        r2 = _function(mode, mid2)
        if mode == 0:
            if r1 < r2:
                return _search(mode, start, mid2, precision, depth + 1)
            if r1 > r2:
                return _search(mode, mid1, end, precision, depth + 1)
        else:
            if r1 < r2:
                return _search(mode, mid1, end, precision, depth + 1)
            if r1 > r2:
                return _search(mode, start, mid2, precision, depth + 1)
        return _search(mode, mid1, mid2, precision, depth + 1)
    return _function(mode, start)


def expected_result(values: list[int] | tuple[int, ...]) -> float:
    if (not isinstance(values, (list, tuple)) or len(values) != EXACT_INPUT_LENGTH
            or any(type(value) is not int for value in values)):
        return INVALID_RESULT
    mode, start_milli, end_milli, precision_milli = values
    center = 1000 if mode == 0 else -1000 if mode == 1 else None
    if (center is None or not -100000 <= start_milli < center < end_milli <= 100000
            or not 1 <= precision_milli <= 8):
        return INVALID_RESULT
    start = _f32(start_milli / 1000.0)
    end = _f32(end_milli / 1000.0)
    precision = _f32(precision_milli / 1000.0)
    result = _search(mode, start, end, precision)
    return float(result) if math.isfinite(result) else INVALID_RESULT
