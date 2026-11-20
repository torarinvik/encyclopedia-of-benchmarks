"""Direct exact-Fraction reference for the Weniger Pochhammer profile."""

from __future__ import annotations

from collections.abc import Sequence
from fractions import Fraction
from math import comb

MIN_N, MAX_N = 0, 8
MIN_K, MAX_K = 3, 4
TERM_LIMIT = 3
MAX_VALID_INPUT_LENGTH = 16
MAX_PARSEABLE_INPUT_LENGTH = 17
MAX_OUTPUT_BYTES = 16
WORKSPACE_BYTES = 0


def _encode_i64(value: int) -> bytes:
    return int(value).to_bytes(8, "little", signed=True)


def _parse(values: Sequence[int] | None, input_is_null: bool,
           input_length: int | None) -> tuple[int, int, list[int]] | None:
    if type(input_is_null) is not bool or input_is_null:
        return None
    if not isinstance(values, (list, tuple)):
        return None
    if input_length is not None and (type(input_length) is not int or input_length != len(values)):
        return None
    if not 7 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH:
        return None
    if any(type(value) is not int for value in values):
        return None
    n, k = values[0], values[1]
    terms = list(values[2:])
    if not MIN_N <= n <= MAX_N or not MIN_K <= k <= MAX_K:
        return None
    if len(values) != n + k + 4:
        return None
    if any(term == 0 or not -TERM_LIMIT <= term <= TERM_LIMIT for term in terms):
        return None
    return n, k, terms


def _rising_fraction(base: int, length: int) -> int:
    product = 1
    for offset in range(length):
        product *= base + offset
    return product


def _transform(n: int, k: int, terms: list[int]) -> Fraction | None:
    partial_sums: list[int] = []
    running_sum = 0
    for term in terms[:n + k + 1]:
        running_sum += term
        partial_sums.append(running_sum)
    numerator = Fraction(0, 1)
    denominator = Fraction(0, 1)
    common_rising = _rising_fraction(n + k + 1, k - 1)
    for j in range(k + 1):
        sign = -1 if j & 1 else 1
        coefficient = Fraction(
            sign * comb(k, j) * _rising_fraction(n + j + 1, k - 1),
            common_rising * terms[n + j + 1],
        )
        numerator += coefficient * partial_sums[n + j]
        denominator += coefficient
    if denominator == 0:
        return None
    return numerator / denominator


def expected_output(values: Sequence[int] | None,
                    output_capacity: int | None = None,
                    output_is_null: bool = False,
                    input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if type(output_is_null) is not bool or type(input_is_null) is not bool:
        return -1, b""
    if output_capacity is not None and (type(output_capacity) is not int or output_capacity < 0):
        return -1, b""
    if input_length is not None and (type(input_length) is not int
                                     or not 0 <= input_length <= MAX_PARSEABLE_INPUT_LENGTH):
        return -1, b""
    parsed = _parse(values, input_is_null, input_length)
    if parsed is None:
        return -1, b""
    n, k, terms = parsed
    result = _transform(n, k, terms)
    if result is None:
        return -1, b""
    if output_is_null or (output_capacity is not None and output_capacity < MAX_OUTPUT_BYTES):
        return -2, b""
    return MAX_OUTPUT_BYTES, _encode_i64(result.numerator) + _encode_i64(result.denominator)
