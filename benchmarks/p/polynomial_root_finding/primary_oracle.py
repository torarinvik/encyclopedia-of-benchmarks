"""Cantor-Zassenhaus splitting of the linear part over F_998244353."""

from __future__ import annotations

from collections.abc import Sequence
import struct

MODULUS = 998_244_353
MAX_N = 8
MAX_INPUT_LENGTH = MAX_N + 2
MAX_OUTPUT_BYTES = 8 * (MAX_N + 1)
INVALID = -1
OUTPUT_ERROR = -2
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1
_PRNG_MODULUS = 2_147_483_647


def _trim(poly: list[int]) -> list[int]:
    while len(poly) > 1 and poly[-1] == 0:
        poly.pop()
    return poly


def _poly_mod(poly: list[int], divisor: list[int]) -> list[int]:
    poly = [value % MODULUS for value in poly]
    divisor = _trim([value % MODULUS for value in divisor])
    if len(divisor) == 1:
        return [0]
    inverse = pow(divisor[-1], MODULUS - 2, MODULUS)
    while len(poly) >= len(divisor) and any(poly):
        shift = len(poly) - len(divisor)
        factor = poly[-1] * inverse % MODULUS
        for index, value in enumerate(divisor):
            at = shift + index
            poly[at] = (poly[at] - factor * value) % MODULUS
        _trim(poly)
    return _trim(poly)


def _poly_mul_mod(left: list[int], right: list[int], modulus_poly: list[int]) -> list[int]:
    product = [0] * (len(left) + len(right) - 1)
    for i, a in enumerate(left):
        for j, b in enumerate(right):
            product[i + j] = (product[i + j] + a * b) % MODULUS
    return _poly_mod(product, modulus_poly)


def _poly_pow_mod(base: list[int], exponent: int, modulus_poly: list[int]) -> list[int]:
    result = [1]
    base = _poly_mod(base, modulus_poly)
    while exponent:
        if exponent & 1:
            result = _poly_mul_mod(result, base, modulus_poly)
        base = _poly_mul_mod(base, base, modulus_poly)
        exponent >>= 1
    return result


def _poly_gcd(left: list[int], right: list[int]) -> list[int]:
    left = _trim([value % MODULUS for value in left])
    right = _trim([value % MODULUS for value in right])
    while right != [0]:
        left, right = right, _poly_mod(left, right)
    if left == [0]:
        return [0]
    inverse = pow(left[-1], MODULUS - 2, MODULUS)
    return [(value * inverse) % MODULUS for value in left]


def _poly_div_exact(poly: list[int], divisor: list[int]) -> list[int]:
    remainder = poly.copy()
    inverse = pow(divisor[-1], MODULUS - 2, MODULUS)
    quotient = [0] * (len(poly) - len(divisor) + 1)
    while len(remainder) >= len(divisor) and any(remainder):
        shift = len(remainder) - len(divisor)
        factor = remainder[-1] * inverse % MODULUS
        quotient[shift] = factor
        for index, value in enumerate(divisor):
            at = shift + index
            remainder[at] = (remainder[at] - factor * value) % MODULUS
        _trim(remainder)
    return _trim(quotient)


def _try_split(poly: list[int], slope: int, offset: int) -> tuple[list[int], list[int]] | None:
    linear = _poly_mod([offset, slope], poly)
    powered = _poly_pow_mod(linear, (MODULUS - 1) // 2, poly)
    powered[0] = (powered[0] - 1) % MODULUS
    part = _poly_gcd(poly, _trim(powered))
    if len(part) <= 1 or len(part) == len(poly):
        return None
    return part, _poly_div_exact(poly, part)


def _split_linear_roots(poly: list[int], roots: list[int], state: int) -> None:
    degree = len(poly) - 1
    if degree == 1:
        roots.append((-poly[0] * pow(poly[1], MODULUS - 2, MODULUS)) % MODULUS)
        return

    for _ in range(32):
        state = state * 48_271 % _PRNG_MODULUS
        slope = state % MODULUS or 1
        state = state * 48_271 % _PRNG_MODULUS
        offset = state % MODULUS
        split = _try_split(poly, slope, offset)
        if split is not None:
            _split_linear_roots(split[0], roots, state)
            _split_linear_roots(split[1], roots, state + 1)
            return

    # For any two distinct roots a,b, the quadratic-character correlation of
    # a+c and b+c is -1 over F_p. Scanning every c therefore finds a split.
    for offset in range(MODULUS):
        split = _try_split(poly, 1, offset)
        if split is not None:
            _split_linear_roots(split[0], roots, state)
            _split_linear_roots(split[1], roots, state + offset + 1)
            return
    raise ArithmeticError("linear-factor split invariant failed")


def _roots(coefficients: list[int]) -> list[int]:
    degree = len(coefficients) - 1
    if degree <= 0:
        return []
    polynomial = _trim(coefficients.copy())
    x_mod = _poly_mod([0, 1], polynomial)
    x_to_p = _poly_pow_mod(x_mod, MODULUS, polynomial)
    x_to_p[0] = (x_to_p[0] - x_mod[0]) % MODULUS
    for index in range(1, len(x_mod)):
        if index >= len(x_to_p):
            x_to_p.extend([0] * (index + 1 - len(x_to_p)))
        x_to_p[index] = (x_to_p[index] - x_mod[index]) % MODULUS
    linear_part = _poly_gcd(polynomial, _trim(x_to_p))
    if len(linear_part) <= 1:
        return []
    seed = (sum((index + 1) * value for index, value in enumerate(coefficients)) + 1)
    seed = seed % (_PRNG_MODULUS - 1) + 1
    found: list[int] = []
    _split_linear_roots(linear_part, found, seed)
    return sorted(set(found))


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
    if len(values) < 2 or len(values) > MAX_INPUT_LENGTH:
        return _invalid()
    if input_length is not None and (type(input_length) is not int or input_length != len(values)):
        return _invalid()
    if any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values):
        return _invalid()
    degree = values[0]
    if type(degree) is not int or not 0 <= degree <= MAX_N or len(values) != degree + 2:
        return _invalid()
    coefficients = list(values[1:])
    if (any(not 0 <= value < MODULUS for value in coefficients)
            or coefficients[-1] == 0):
        return _invalid()

    roots = _roots(coefficients)
    words = [len(roots), *roots]
    byte_count = 8 * len(words)
    if output_is_null or (output_capacity is not None and
                          (type(output_capacity) is not int or output_capacity < byte_count)):
        return OUTPUT_ERROR, b""
    return byte_count, b"".join(struct.pack("<q", value) for value in words)
