"""Runtime oracle for source-ordered reduced rational addition."""
import struct

MAX_INPUT_LENGTH = 4
MAX_OUTPUT_BYTES = 16


def _gcd(a: int, b: int) -> int:
    a, b = abs(a), abs(b)
    while b:
        a, b = b, a % b
    return a


def expected_output(values):
    if (not isinstance(values, (list, tuple)) or len(values) != 4
            or any(type(value) is not int or not -(2**63) <= value < 2**63 for value in values)):
        return -1, b""
    n1, d1, n2, d2 = values
    if (abs(n1) > 10000 or abs(n2) > 10000 or abs(d1) > 1000 or abs(d2) > 1000
            or d1 == 0 or d2 == 0):
        return -1, b""
    common = _gcd(d1, d2)
    left = (d2 // common) * n1
    right = (d1 // common) * n2
    numerator = left + right
    denominator = (d1 // common) * d2
    divisor = _gcd(numerator, denominator)
    numerator //= divisor
    denominator //= divisor
    if denominator < 0:
        numerator, denominator = -numerator, -denominator
    return 16, struct.pack("<qq", numerator, denominator)
