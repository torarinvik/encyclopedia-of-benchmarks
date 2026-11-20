"""Integer product-cleared reference for one DLMF Levin transform."""

from __future__ import annotations

from collections.abc import Sequence
from math import comb, gcd

MIN_N, MAX_N = 0, 8
MIN_K, MAX_K = 1, 3
TERM_LIMIT = 3
MAX_VALID_INPUT_LENGTH = MAX_N + MAX_K + 4
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_OUTPUT_BYTES = 16
WORKSPACE_BYTES = 0


def _i64_bytes(value: int) -> bytes:
    return int(value).to_bytes(8, "little", signed=True)


def _parse(values: Sequence[int] | None, input_is_null: bool,
           input_length: int | None) -> tuple[int, int, list[int]] | None:
    if type(input_is_null) is not bool or input_is_null:
        return None
    if not isinstance(values, (list, tuple)):
        return None
    if input_length is not None and (
            type(input_length) is not int or input_length != len(values)):
        return None
    if not 2 + MIN_N + MIN_K + 2 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH:
        return None
    if any(type(value) is not int for value in values):
        return None
    n, k = values[0], values[1]
    if not MIN_N <= n <= MAX_N or not MIN_K <= k <= MAX_K:
        return None
    if len(values) != n + k + 4:
        return None
    terms = list(values[2:])
    if any(term == 0 or term < -TERM_LIMIT or term > TERM_LIMIT for term in terms):
        return None
    return n, k, terms


def _transform(n: int, k: int, terms: list[int]) -> tuple[int, int] | None:
    product = 1
    for j in range(k + 1):
        product *= terms[n + j + 1]
    numerator = 0
    denominator = 0
    for j in range(k + 1):
        base = n + j + 1
        power = 1
        for _ in range(k - 1):
            power *= base
        weight = comb(k, j) * power * (product // terms[n + j + 1])
        if j & 1:
            weight = -weight
        partial = sum(terms[:n + j + 1])
        numerator += weight * partial
        denominator += weight
    if denominator == 0:
        return None
    if denominator < 0:
        numerator, denominator = -numerator, -denominator
    divisor = gcd(abs(numerator), denominator)
    return numerator // divisor, denominator // divisor


def expected_output(values: Sequence[int] | None,
                    output_capacity: int | None = None,
                    output_is_null: bool = False,
                    input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if type(output_is_null) is not bool or type(input_is_null) is not bool:
        return -1, b""
    if output_capacity is not None and (
            type(output_capacity) is not int or output_capacity < 0):
        return -1, b""
    if input_length is not None and (
            type(input_length) is not int
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
    numerator, denominator = result
    return MAX_OUTPUT_BYTES, _i64_bytes(numerator) + _i64_bytes(denominator)
