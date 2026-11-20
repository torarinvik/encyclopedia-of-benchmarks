"""Cipolla pair-exponentiation reference for modular square roots."""

from __future__ import annotations

from collections.abc import Sequence

MAX_PRIME = 1_000_003
MAX_VALID_INPUT_LENGTH = 2
MAX_PARSEABLE_INPUT_LENGTH = 3


def _decode(values: Sequence[int] | None, input_length: int | None,
            input_is_null: bool) -> tuple[int, int] | None:
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple))
            or len(values) > MAX_PARSEABLE_INPUT_LENGTH
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return None
    if input_length is not None and (
            type(input_length) is not int or input_length != len(values)):
        return None
    if len(values) != 2:
        return None
    residue, prime = values
    if prime < 3 or prime > MAX_PRIME or prime % 2 == 0 or not 0 <= residue < prime:
        return None
    return residue, prime


def _legendre(value: int, prime: int) -> int:
    symbol = pow(value % prime, (prime - 1) // 2, prime)
    return -1 if symbol == prime - 1 else symbol


def _multiply(left: tuple[int, int], right: tuple[int, int],
              radicand: int, prime: int) -> tuple[int, int]:
    a, b = left
    c, d = right
    return ((a * c + radicand * b * d) % prime,
            (a * d + b * c) % prime)


def _power(base: tuple[int, int], exponent: int, radicand: int,
           prime: int) -> tuple[int, int]:
    result = (1, 0)
    factor = base
    while exponent:
        if exponent & 1:
            result = _multiply(result, factor, radicand, prime)
        factor = _multiply(factor, factor, radicand, prime)
        exponent >>= 1
    return result


def expected_result(values: Sequence[int] | None,
                    input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    decoded = _decode(values, input_length, input_is_null)
    if decoded is None:
        return -1
    residue, prime = decoded
    if residue == 0:
        return 0
    if _legendre(residue, prime) != 1:
        return -1
    parameter = 0
    while parameter < prime:
        radicand = (parameter * parameter - residue) % prime
        if _legendre(radicand, prime) == -1:
            root, extension_part = _power(
                (parameter, 1), (prime + 1) // 2, radicand, prime)
            if extension_part == 0:
                return min(root, prime - root)
            return -1
        parameter += 1
    return -1
