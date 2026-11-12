"""Direct long-division oracle for bounded polynomials over F_998244353."""

from __future__ import annotations

from collections.abc import Sequence
import struct

MODULUS = 998_244_353
MAX_N = 64
MAX_INPUT_LENGTH = 131
MAX_OUTPUT_BYTES = 536
INVALID = -1
OUTPUT_ERROR = -2
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1


def _invalid() -> tuple[int, bytes]:
    return INVALID, b""


def _trim(coefficients: list[int]) -> list[int]:
    while coefficients and coefficients[-1] == 0:
        coefficients.pop()
    return coefficients


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

    n, m = values[0], values[1]
    if not 1 <= n <= MAX_N or not 1 <= m <= MAX_N or len(values) != 2 + n + m:
        return _invalid()
    dividend = list(values[2:2 + n])
    divisor = list(values[2 + n:])
    if any(not 0 <= coefficient < MODULUS for coefficient in dividend + divisor):
        return _invalid()
    if dividend[-1] == 0 or divisor[-1] == 0:
        return _invalid()

    work = dividend.copy()
    quotient = [0] * max(0, n - m + 1)
    if n >= m:
        inverse_leading = pow(divisor[-1], MODULUS - 2, MODULUS)
        for shift in range(n - m, -1, -1):
            factor = work[shift + m - 1] * inverse_leading % MODULUS
            quotient[shift] = factor
            for degree, divisor_coefficient in enumerate(divisor):
                index = shift + degree
                work[index] = (work[index] - factor * divisor_coefficient) % MODULUS

    quotient = _trim(quotient)
    remainder = _trim(work[:min(n, m)])
    byte_count = 8 * (2 + len(quotient) + len(remainder))
    if byte_count > MAX_OUTPUT_BYTES:
        return _invalid()
    if output_is_null or (output_capacity is not None and
                          (type(output_capacity) is not int or output_capacity < byte_count)):
        return OUTPUT_ERROR, b""

    words = [len(quotient), len(remainder), *quotient, *remainder]
    return byte_count, b"".join(struct.pack("<q", word) for word in words)
