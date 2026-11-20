"""Unexecuted models of indexed Calkin–Wilf fractions."""

import struct
from functools import lru_cache


def parse(values):
    if (not isinstance(values, (list, tuple)) or len(values) != 1
            or type(values[0]) is not int or not 1 <= values[0] < 1 << 62):
        return None
    return values[0]


def fraction(values):
    index = parse(values)
    if index is None:
        return None
    numerator, denominator = 1, 1
    for bit in range(index.bit_length()-2, -1, -1):
        if index & (1 << bit):
            numerator += denominator
        else:
            denominator += numerator
    return numerator, denominator


def independent_fraction(values):
    index = parse(values)
    if index is None:
        return None

    @lru_cache(maxsize=None)
    def stern(n):
        if n < 2:
            return n
        if n % 2 == 0:
            return stern(n//2)
        return stern(n//2) + stern(n//2+1)

    return stern(index), stern(index+1)


def expected_output(values, capacity=16, output_is_null=False, input_is_null=False, input_length=None):
    if input_is_null or (input_length is not None and input_length != len(values)):
        return -1, b""
    result = fraction(values)
    if result is None:
        return -1, b""
    if output_is_null or capacity < 16:
        return -2, b""
    return 16, struct.pack("<qq", *result)


def independent_output(values, capacity=16, output_is_null=False, input_is_null=False, input_length=None):
    if input_is_null or (input_length is not None and input_length != len(values)):
        return -1, b""
    result = independent_fraction(values)
    if result is None:
        return -1, b""
    if output_is_null or capacity < 16:
        return -2, b""
    return 16, struct.pack("<qq", *result)
