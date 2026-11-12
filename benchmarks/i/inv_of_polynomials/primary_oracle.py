"""Polynomial extended-Euclid oracle for inverse modulo an arbitrary g."""

from __future__ import annotations

from collections.abc import Sequence
import struct

MODULUS = 998_244_353
MAX_LENGTH = 6
MAX_INPUT_LENGTH = 2 + 2 * MAX_LENGTH
MAX_OUTPUT_BYTES = 8 * (MAX_LENGTH - 1)
INVALID = -1
OUTPUT_ERROR = -2
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1


def _trim(poly: list[int]) -> list[int]:
    while poly and poly[-1] == 0:
        poly.pop()
    return poly


def _subtract(left: list[int], right: list[int]) -> list[int]:
    result = [0] * max(len(left), len(right))
    for index in range(len(result)):
        a = left[index] if index < len(left) else 0
        b = right[index] if index < len(right) else 0
        result[index] = (a - b) % MODULUS
    return _trim(result)


def _multiply(left: list[int], right: list[int]) -> list[int]:
    if not left or not right:
        return []
    result = [0] * (len(left) + len(right) - 1)
    for i, a in enumerate(left):
        for j, b in enumerate(right):
            result[i + j] = (result[i + j] + a * b) % MODULUS
    return _trim(result)


def _divmod_poly(dividend: list[int], divisor: list[int]) -> tuple[list[int], list[int]]:
    remainder = dividend[:]
    if not remainder or len(remainder) < len(divisor):
        return [], remainder
    quotient = [0] * (len(remainder) - len(divisor) + 1)
    inverse_lead = pow(divisor[-1], MODULUS - 2, MODULUS)
    while remainder and len(remainder) >= len(divisor):
        shift = len(remainder) - len(divisor)
        factor = remainder[-1] * inverse_lead % MODULUS
        quotient[shift] = factor
        for index, coefficient in enumerate(divisor):
            remainder[shift + index] = (
                remainder[shift + index] - factor * coefficient
            ) % MODULUS
        _trim(remainder)
    return _trim(quotient), remainder


def _inverse_polynomial(f: list[int], g: list[int]) -> list[int] | None:
    if len(g) == 1:
        return []  # The quotient by a nonzero constant has only the zero class.
    _, first_remainder = _divmod_poly(f, g)
    r0, r1 = g[:], first_remainder
    s0, s1 = [], [1]
    while r1:
        quotient, remainder = _divmod_poly(r0, r1)
        next_s = _subtract(s0, _multiply(quotient, s1))
        r0, r1 = r1, remainder
        s0, s1 = s1, next_s
    if len(r0) != 1:
        return None
    scale = pow(r0[0], MODULUS - 2, MODULUS)
    inverse = [(coefficient * scale) % MODULUS for coefficient in s0]
    _, inverse = _divmod_poly(inverse, g)
    return _trim(inverse)


def _invalid() -> tuple[int, bytes]:
    return INVALID, b""


def expected_output(
    values: Sequence[int] | None,
    output_capacity: int | None = None,
    output_is_null: bool = False,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> tuple[int, bytes]:
    if type(output_is_null) is not bool or type(input_is_null) is not bool:
        return _invalid()
    if input_is_null or not isinstance(values, (list, tuple)):
        return _invalid()
    if len(values) < 4 or len(values) > MAX_INPUT_LENGTH:
        return _invalid()
    if input_length is not None and (type(input_length) is not int or input_length != len(values)):
        return _invalid()
    if any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values):
        return _invalid()
    n, m = values[:2]
    if not 1 <= n <= MAX_LENGTH or not 1 <= m <= MAX_LENGTH or len(values) != 2 + n + m:
        return _invalid()
    f = list(values[2:2 + n])
    g = list(values[2 + n:])
    if (any(not 0 <= value < MODULUS for value in f + g)
            or f[-1] == 0 or g[-1] == 0):
        return _invalid()

    inverse = _inverse_polynomial(f, g)
    if inverse is None:
        return INVALID, b""
    byte_count = 8 * len(inverse)
    if output_is_null or (output_capacity is not None and
                          (type(output_capacity) is not int or output_capacity < byte_count)):
        return OUTPUT_ERROR, b""
    encoded = b"".join(struct.pack("<q", coefficient) for coefficient in inverse)
    return byte_count, encoded
