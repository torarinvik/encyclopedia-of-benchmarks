"""Pinned-formula oracle for the five Graham's law operations."""

from __future__ import annotations

import math
import struct

INVALID_RESULT = -1e300
MIN_OPERAND = 1e-6
MAX_OPERAND = 1e6
MAX_RESULT = 1e6
ROUNDING_GUARD = 1e-3


def encode_float(value: float) -> int:
    """Represent one binary64 value as its signed-i64 ABI bit pattern."""
    return struct.unpack("<q", struct.pack("<d", value))[0]


def decode_float(bits: int) -> float:
    return struct.unpack("<d", struct.pack("<q", bits))[0]


def grahams_law(values: list[int]) -> float:
    if (len(values) not in (3, 4) or type(values[0]) is not int
            or not 0 <= values[0] <= 4
            or (values[0] == 0 and len(values) != 3)
            or (values[0] != 0 and len(values) != 4)):
        return INVALID_RESULT
    operands = [decode_float(bits) for bits in values[1:]]
    if any(not math.isfinite(value) or not MIN_OPERAND <= value <= MAX_OPERAND
           for value in operands):
        return INVALID_RESULT
    operation = values[0]
    if operation == 0:
        first, second = operands
        result = math.sqrt(second / first)
    elif operation == 1:
        rate, first_mass, second_mass = operands
        result = rate * math.sqrt(second_mass / first_mass)
    elif operation == 2:
        rate, first_mass, second_mass = operands
        result = rate / math.sqrt(second_mass / first_mass)
    elif operation == 3:
        first_mass, first_rate, second_rate = operands
        result = first_mass / math.pow(first_rate / second_rate, 2.0)
    else:
        first_mass, first_rate, second_rate = operands
        result = math.pow(first_rate / second_rate, 2.0) / first_mass
    if not math.isfinite(result) or not 0.0 <= result <= MAX_RESULT:
        return INVALID_RESULT
    scaled = result * 1_000_000.0
    fraction = scaled - math.floor(scaled)
    if 0.5 - ROUNDING_GUARD <= fraction <= 0.5 + ROUNDING_GUARD:
        return INVALID_RESULT
    return round(result, 6)
