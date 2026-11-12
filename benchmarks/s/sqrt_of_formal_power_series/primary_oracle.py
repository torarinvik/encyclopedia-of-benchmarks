"""Tonelli-Shanks plus the coefficient recurrence for a formal square root."""

from __future__ import annotations

from collections.abc import Sequence
import struct

MODULUS = 998_244_353
MAX_N = 64
MAX_INPUT_LENGTH = 66
MAX_OUTPUT_BYTES = 512
INVALID = -1
OUTPUT_ERROR = -2


def _invalid() -> tuple[int, bytes]:
    return INVALID, b""


def _mod_pow(base: int, exponent: int) -> int:
    result = 1
    base %= MODULUS
    while exponent:
        if exponent & 1:
            result = result * base % MODULUS
        base = base * base % MODULUS
        exponent >>= 1
    return result


def _canonical_sqrt(value: int) -> int | None:
    if value == 0:
        return 0
    if _mod_pow(value, (MODULUS - 1) // 2) != 1:
        return None

    odd_part = MODULUS - 1
    twos = 0
    while odd_part % 2 == 0:
        odd_part //= 2
        twos += 1
    non_residue = 2
    while _mod_pow(non_residue, (MODULUS - 1) // 2) != MODULUS - 1:
        non_residue += 1

    c = _mod_pow(non_residue, odd_part)
    root = _mod_pow(value, (odd_part + 1) // 2)
    remainder = _mod_pow(value, odd_part)
    order = twos
    while remainder != 1:
        index = 1
        probe = remainder * remainder % MODULUS
        while index < order and probe != 1:
            probe = probe * probe % MODULUS
            index += 1
        if index >= order or probe != 1:
            return None
        factor = _mod_pow(c, 1 << (order - index - 1))
        root = root * factor % MODULUS
        factor_squared = factor * factor % MODULUS
        remainder = remainder * factor_squared % MODULUS
        c = factor_squared
        order = index
    return min(root, MODULUS - root)


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
    if len(values) < 2 or len(values) > MAX_INPUT_LENGTH:
        return _invalid()
    if input_length is not None and (type(input_length) is not int or input_length != len(values)):
        return _invalid()
    if any(type(value) is not int or not -(1 << 63) <= value < (1 << 63) for value in values):
        return _invalid()
    n = values[0]
    if not 1 <= n <= MAX_N or len(values) != n + 1:
        return _invalid()
    coefficients = values[1:]
    if any(not 0 <= value < MODULUS for value in coefficients):
        return _invalid()

    if output_is_null or (output_capacity is not None and
                          (type(output_capacity) is not int or output_capacity < 8 * n)):
        return OUTPUT_ERROR, b""

    valuation = next((degree for degree, value in enumerate(coefficients) if value != 0), None)
    if valuation is None:
        return 8 * n, bytes(8 * n)
    if valuation % 2:
        return 8, struct.pack("<q", -1)

    shift = valuation // 2
    constant_root = _canonical_sqrt(coefficients[valuation])
    if constant_root is None:
        return 8, struct.pack("<q", -1)
    inverse_twice_root = _mod_pow((2 * constant_root) % MODULUS, MODULUS - 2)
    result = [0] * n
    width = n - valuation
    result[shift] = constant_root
    for degree in range(1, width):
        cross_terms = 0
        for index in range(1, degree):
            cross_terms = (cross_terms + result[shift + index] *
                           result[shift + degree - index]) % MODULUS
        target = coefficients[valuation + degree]
        result[shift + degree] = (target - cross_terms) * inverse_twice_root % MODULUS
    encoded = b"".join(struct.pack("<q", coefficient) for coefficient in result)
    return 8 * n, encoded
