"""Exact rational oracle for the bounded Java EgyptianFraction contract."""

from __future__ import annotations

from fractions import Fraction
import struct

I64_MIN = -(2**63)
I64_MAX = 2**63 - 1
MAX_INPUT_LENGTH = 3
MAX_OUTPUT_BYTES = 12


def expected_output(values: list[int] | tuple[int, ...]) -> tuple[int, bytes]:
    """Return little-endian i32 unit denominators in source order."""
    if (not isinstance(values, (list, tuple)) or len(values) != 2
            or any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values)):
        return -1, b""
    numerator, denominator = values
    if not 0 <= numerator <= denominator <= 10 or denominator == 0:
        return -1, b""
    remaining = Fraction(numerator, denominator)
    terms: list[int] = []
    while remaining:
        unit_denominator = (remaining.denominator + remaining.numerator - 1) // remaining.numerator
        terms.append(unit_denominator)
        remaining -= Fraction(1, unit_denominator)
    try:
        output = b"".join(struct.pack("<i", value) for value in terms)
    except struct.error:
        return -1, b""
    return len(output), output
