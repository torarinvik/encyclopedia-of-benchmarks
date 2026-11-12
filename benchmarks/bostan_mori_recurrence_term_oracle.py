"""Bostan–Mori coefficient extraction for a bounded linear recurrence."""

from __future__ import annotations

from collections.abc import Sequence

MODULUS = 998_244_353
MAX_ORDER = 8
MAX_INDEX = 10**18
MAX_VALID_INPUT_LENGTH = 2 + 2 * MAX_ORDER
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1


def _convolve(left: list[int], right: list[int]) -> list[int]:
    product = [0] * (len(left) + len(right) - 1)
    for i, first in enumerate(left):
        for j, second in enumerate(right):
            product[i + j] = (product[i + j] + first * second) % MODULUS
    return product


def expected_result(values: Sequence[int] | None) -> int:
    if not isinstance(values, (list, tuple)) or len(values) < 2:
        return -1
    order, index = values[0], values[1]
    if (type(order) is not int or not 1 <= order <= MAX_ORDER
            or type(index) is not int or not 0 <= index <= MAX_INDEX
            or len(values) != 2 + 2 * order):
        return -1

    coefficients = list(values[2:2 + order])
    initial = list(values[2 + order:])
    if any(type(value) is not int or not 0 <= value < MODULUS
           for value in (*coefficients, *initial)):
        return -1

    denominator = [1, *((-coefficient) % MODULUS for coefficient in coefficients)]
    numerator = _convolve(initial, denominator)[:order]
    remaining = index
    while remaining:
        denominator_negative = [
            coefficient if degree % 2 == 0 else (-coefficient) % MODULUS
            for degree, coefficient in enumerate(denominator)
        ]
        numerator_product = _convolve(numerator, denominator_negative)
        denominator_product = _convolve(denominator, denominator_negative)
        parity = remaining & 1
        numerator = [
            numerator_product[2 * degree + parity]
            if 2 * degree + parity < len(numerator_product) else 0
            for degree in range(order)
        ]
        denominator = [
            denominator_product[2 * degree]
            if 2 * degree < len(denominator_product) else 0
            for degree in range(order + 1)
        ]
        remaining >>= 1

    return numerator[0] * pow(denominator[0], MODULUS - 2, MODULUS) % MODULUS
