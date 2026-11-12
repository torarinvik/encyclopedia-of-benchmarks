"""Recursive exhaustive divisor splitting, independent of the factor sieve."""

from __future__ import annotations

from collections import Counter
from collections.abc import Sequence
import struct

_FIELD_PRIMES = {2, 3, 5}
_DEGREE_LIMIT = 8
_WORD_LIMIT = 12
_BYTE_LIMIT = 264


def _normalize(poly: list[int]) -> list[int]:
    while len(poly) > 1 and poly[-1] == 0:
        poly.pop()
    return poly


def _candidate(degree: int, code: int, p: int) -> list[int]:
    lower = []
    for _ in range(degree):
        lower.append(code % p)
        code //= p
    return lower + [1]


def _divide(poly: list[int], divisor: list[int], p: int) -> tuple[list[int], list[int]]:
    quotient = [0] * (len(poly) - len(divisor) + 1)
    rest = poly.copy()
    for shift in range(len(quotient) - 1, -1, -1):
        coefficient = rest[shift + len(divisor) - 1]
        quotient[shift] = coefficient
        for j, value in enumerate(divisor):
            rest[shift + j] = (rest[shift + j] - coefficient * value) % p
    remainder = _normalize(rest[:len(divisor) - 1] or [0])
    return _normalize(quotient), remainder


def _split(poly: list[int], p: int) -> list[tuple[int, ...]]:
    degree = len(poly) - 1
    if degree <= 1:
        return [tuple(poly)]
    for divisor_degree in range(1, degree // 2 + 1):
        for code in range(p ** divisor_degree):
            divisor = _candidate(divisor_degree, code, p)
            quotient, remainder = _divide(poly, divisor, p)
            if len(remainder) == 1 and remainder[0] == 0:
                return _split(divisor, p) + _split(quotient, p)
    return [tuple(poly)]


def _reference(words: list[int], p: int) -> bytes:
    coefficients = words[2:]
    factored = Counter(_split(coefficients, p))
    records = sorted(factored.items(), key=lambda item: (len(item[0]), item[0]))
    output_words = [len(records)]
    for factor, multiplicity in records:
        output_words.extend((multiplicity, len(factor) - 1, *factor))
    return b"".join(struct.pack("<q", value) for value in output_words)


def expected_output(
    values: Sequence[int] | None,
    output_capacity: int | None = None,
    output_is_null: bool = False,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> tuple[int, bytes]:
    if type(output_is_null) is not bool or type(input_is_null) is not bool:
        return -1, b""
    if input_is_null or not isinstance(values, (tuple, list)):
        return -1, b""
    if len(values) < 3 or len(values) > _WORD_LIMIT:
        return -1, b""
    if input_length is not None and (type(input_length) is not int or input_length != len(values)):
        return -1, b""
    if any(type(value) is not int or not -(1 << 63) <= value < (1 << 63) for value in values):
        return -1, b""
    degree, p = values[:2]
    if not 0 <= degree <= _DEGREE_LIMIT or p not in _FIELD_PRIMES:
        return -1, b""
    if len(values) != degree + 3:
        return -1, b""
    coefficients = values[2:]
    if coefficients[-1] != 1 or any(c < 0 or c >= p for c in coefficients):
        return -1, b""

    output = _reference(list(values), p)
    if len(output) > _BYTE_LIMIT:
        return -1, b""
    if output_is_null or (output_capacity is not None and
                          (type(output_capacity) is not int or output_capacity < len(output))):
        return -2, b""
    return len(output), output
