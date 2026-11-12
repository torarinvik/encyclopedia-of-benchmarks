"""Bounded exhaustive irreducible-factor enumeration over small prime fields."""

from __future__ import annotations

from collections.abc import Sequence
import struct

PRIMES = (2, 3, 5)
MAX_N = 8
MAX_INPUT_LENGTH = 12
MAX_OUTPUT_BYTES = 264


def _trim(poly: list[int]) -> list[int]:
    while len(poly) > 1 and poly[-1] == 0:
        poly.pop()
    return poly


def _monic_from_code(degree: int, code: int, prime: int) -> list[int]:
    coefficients: list[int] = []
    for _ in range(degree):
        coefficients.append(code % prime)
        code //= prime
    coefficients.append(1)
    return coefficients


def _exact_quotient(poly: list[int], divisor: list[int], prime: int) -> list[int] | None:
    degree = len(divisor) - 1
    if len(poly) - 1 < degree:
        return None
    remainder = poly.copy()
    quotient = [0] * (len(poly) - degree)
    for shift in range(len(poly) - degree - 1, -1, -1):
        factor = remainder[shift + degree]
        quotient[shift] = factor
        if factor:
            for offset in range(degree + 1):
                remainder[shift + offset] = (
                    remainder[shift + offset] - factor * divisor[offset]
                ) % prime
    if any(remainder[:degree]):
        return None
    return _trim(quotient)


def _is_irreducible(candidate: list[int], prime: int) -> bool:
    degree = len(candidate) - 1
    for divisor_degree in range(1, degree // 2 + 1):
        for code in range(prime ** divisor_degree):
            divisor = _monic_from_code(divisor_degree, code, prime)
            if _exact_quotient(candidate, divisor, prime) is not None:
                return False
    return True


def _factor(coefficients: list[int], prime: int) -> list[tuple[int, list[int]]]:
    work = coefficients.copy()
    factors: list[tuple[int, list[int]]] = []
    original_degree = len(work) - 1
    for degree in range(1, original_degree // 2 + 1):
        for code in range(prime ** degree):
            candidate = _monic_from_code(degree, code, prime)
            if not _is_irreducible(candidate, prime):
                continue
            multiplicity = 0
            while len(work) - 1 >= degree:
                quotient = _exact_quotient(work, candidate, prime)
                if quotient is None:
                    break
                work = quotient
                multiplicity += 1
            if multiplicity:
                factors.append((multiplicity, candidate))
    if len(work) > 1:
        factors.append((1, work))
    factors.sort(key=lambda item: (len(item[1]), tuple(item[1])))
    return factors


def _bad() -> tuple[int, bytes]:
    return -1, b""


def _encode(factors: list[tuple[int, list[int]]]) -> tuple[int, bytes]:
    words = [len(factors)]
    for multiplicity, coefficients in factors:
        words.extend((multiplicity, len(coefficients) - 1, *coefficients))
    payload = b"".join(struct.pack("<q", word) for word in words)
    if len(payload) > MAX_OUTPUT_BYTES:
        return _bad()
    return len(payload), payload


def expected_output(
    values: Sequence[int] | None,
    output_capacity: int | None = None,
    output_is_null: bool = False,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> tuple[int, bytes]:
    if type(output_is_null) is not bool or type(input_is_null) is not bool:
        return _bad()
    if input_is_null or not isinstance(values, (list, tuple)):
        return _bad()
    size = len(values)
    if size < 3 or size > MAX_INPUT_LENGTH:
        return _bad()
    if input_length is not None and (type(input_length) is not int or input_length != size):
        return _bad()
    if any(type(value) is not int or not -(1 << 63) <= value < (1 << 63) for value in values):
        return _bad()

    degree, prime = values[:2]
    if type(degree) is not int or not 0 <= degree <= MAX_N or prime not in PRIMES:
        return _bad()
    if size != degree + 3:
        return _bad()
    coefficients = list(values[2:])
    if coefficients[-1] != 1 or any(value < 0 or value >= prime for value in coefficients):
        return _bad()

    factors = _factor(coefficients, prime)
    required_bytes = 8 * (1 + sum(2 + len(poly) for _, poly in factors))
    if output_is_null or (output_capacity is not None and
                          (type(output_capacity) is not int or output_capacity < required_bytes)):
        return -2, b""
    return _encode(factors)
