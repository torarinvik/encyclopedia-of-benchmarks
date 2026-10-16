"""Exact integer-subset oracle for the shared complex-number operations."""

from __future__ import annotations

import struct

MAX_INPUT_LENGTH = 5
MAX_COMPONENT = 100_000
OUTPUT_BYTES = 16


def expected_output(values: tuple[int, ...] | list[int], output_capacity: int = OUTPUT_BYTES) -> tuple[int, bytes]:
    if (not isinstance(values, (tuple, list)) or len(values) != MAX_INPUT_LENGTH
            or any(type(value) is not int or not -(2**63) <= value < 2**63 for value in values)):
        return -1, b""
    operation, ar, ai, br, bi = values
    if (not 0 <= operation <= 5
            or any(abs(value) > MAX_COMPONENT for value in (ar, ai, br, bi))):
        return -1, b""

    if operation == 0:
        result = (ar + br, ai + bi)
    elif operation == 1:
        result = (ar - br, ai - bi)
    elif operation == 2:
        result = (ar * br - ai * bi, ar * bi + ai * br)
    elif operation == 3:
        denominator = br * br + bi * bi
        if denominator == 0:
            return -1, b""
        real_numerator = ar * br + ai * bi
        imaginary_numerator = ai * br - ar * bi
        if real_numerator % denominator or imaginary_numerator % denominator:
            return -1, b""
        result = (real_numerator // denominator, imaginary_numerator // denominator)
    elif operation == 4:
        result = (ar, -ai)
    else:
        result = (int(ar == br and ai == bi), 0)

    if output_capacity < OUTPUT_BYTES:
        return -2, b""
    return 2, struct.pack("<qq", *result)
