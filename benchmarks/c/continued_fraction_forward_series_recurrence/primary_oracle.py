"""Forward rho/term recurrence reference for the bounded finite-field profile."""

from __future__ import annotations

import struct
from typing import Sequence

ALGORITHM = "continued_fraction_forward_series_recurrence"
MODULUS = 998244353
MIN_COEFFICIENTS = 2
MAX_COEFFICIENTS = 9
MAX_VALID_INPUT_LENGTH = 10
MAX_PARSEABLE_INPUT_LENGTH = 11
MAX_OUTPUT_BYTES = 80
INVALID_RESULT = -1
OUTPUT_ERROR_RESULT = -2
WORKSPACE_BYTES = 0


def _coefficients(values: Sequence[int] | None, input_is_null: bool,
                  input_length: int | None) -> list[int] | None:
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple))
            or (input_length is not None
                and (type(input_length) is not int or input_length != len(values)))
            or not MIN_COEFFICIENTS + 1 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return None
    count = values[0]
    if not MIN_COEFFICIENTS <= count <= MAX_COEFFICIENTS or len(values) != count + 1:
        return None
    coefficients = list(values[1:])
    if any(not 0 <= value < MODULUS for value in coefficients):
        return None
    return coefficients


def _modular_divisors_are_nonzero(coefficients: Sequence[int]) -> bool:
    rho = 0
    for coefficient in coefficients[1:]:
        product = coefficient * (1 + rho) % MODULUS
        denominator = (1 + MODULUS - product) % MODULUS
        if denominator == 0:
            return False
        rho = product * pow(denominator, MODULUS - 2, MODULUS) % MODULUS
    return True


def forward_partial_sums(coefficients: Sequence[int]) -> list[int] | None:
    if not _modular_divisors_are_nonzero(coefficients):
        return None
    rho = 0
    term = coefficients[0]
    total = term
    sums = [total]
    for coefficient in coefficients[1:]:
        product = coefficient * (1 + rho) % MODULUS
        denominator = (1 + MODULUS - product) % MODULUS
        rho = product * pow(denominator, MODULUS - 2, MODULUS) % MODULUS
        term = rho * term % MODULUS
        total = (total + term) % MODULUS
        sums.append(total)
    return sums


def expected_output(values: Sequence[int] | None,
                    capacity: int = MAX_OUTPUT_BYTES,
                    output_is_null: bool = False,
                    input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    coefficients = _coefficients(values, input_is_null, input_length)
    if coefficients is None:
        return INVALID_RESULT, b""
    sums = forward_partial_sums(coefficients)
    if sums is None:
        return INVALID_RESULT, b""
    required = 8 * (len(coefficients) + 1)
    if (type(output_is_null) is not bool or output_is_null
            or type(capacity) is not int or capacity < required):
        return OUTPUT_ERROR_RESULT, b""
    words = [len(coefficients), *sums]
    return required, struct.pack("<" + "q" * len(words), *words)
