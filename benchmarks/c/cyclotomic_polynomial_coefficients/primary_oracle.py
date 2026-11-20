"""Exact proper-divisor quotient reference for cyclotomic polynomials."""

from __future__ import annotations

import struct
from collections.abc import Sequence

ALGORITHM = "cyclotomic_polynomial_coefficients"
MAX_N = 32
MAX_VALID_INPUT_LENGTH = 1
MAX_PARSEABLE_INPUT_LENGTH = 2
MAX_OUTPUT_BYTES = 248
WORKSPACE_BYTES = 16_384
INVALID_RESULT = -1
OUTPUT_ERROR_RESULT = -2


def coefficients_through(n: int) -> list[int]:
    """Build Phi_1..Phi_n by exact monic division of x^k-1."""
    polynomials: list[list[int]] = [[] for _ in range(n + 1)]
    polynomials[1] = [-1, 1]
    for k in range(2, n + 1):
        divisor = [1]
        for d in range(1, k):
            if k % d:
                continue
            product = [0] * (len(divisor) + len(polynomials[d]) - 1)
            for i, left in enumerate(divisor):
                for j, right in enumerate(polynomials[d]):
                    product[i + j] += left * right
            divisor = product

        remainder = [-1] + [0] * (k - 1) + [1]
        quotient = [0] * (k - len(divisor) + 2)
        divisor_degree = len(divisor) - 1
        for q in range(len(quotient) - 1, -1, -1):
            leading = remainder[divisor_degree + q]
            quotient[q] = leading
            for j, value in enumerate(divisor):
                remainder[q + j] -= leading * value
        if any(remainder):
            raise ArithmeticError("proper-divisor product did not divide x^k-1")
        polynomials[k] = quotient
    return polynomials[n]


def _parse(values: Sequence[int] | None, input_is_null: bool,
           input_length: int | None) -> int | None:
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple))
            or (input_length is not None
                and (type(input_length) is not int or input_length != len(values)))
            or not 1 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return None
    if len(values) != 1 or not 1 <= values[0] <= MAX_N:
        return None
    return values[0]


def expected_output(values: Sequence[int] | None,
                    capacity: int | None = None,
                    output_is_null: bool = False,
                    input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    n = _parse(values, input_is_null, input_length)
    if n is None:
        return INVALID_RESULT, b""
    result = coefficients_through(n)
    required = 8 * len(result)
    effective_capacity = MAX_OUTPUT_BYTES if capacity is None else capacity
    if (type(output_is_null) is not bool or output_is_null
            or type(effective_capacity) is not int or effective_capacity < required):
        return OUTPUT_ERROR_RESULT, b""
    return required, struct.pack("<" + "q" * len(result), *result)
