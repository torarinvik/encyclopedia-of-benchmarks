"""Segmented-sieve reference for the bounded Fortunate-number search."""

from __future__ import annotations

from collections.abc import Sequence
from math import isqrt

I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1
MAX_N = 10
MAX_VALID_INPUT_LENGTH = 1
MAX_PARSEABLE_INPUT_LENGTH = 2
SEARCH_MAX = 64

MAX_SIEVE_LIMIT = 80_434
MAX_SIEVE_FLAGS_BYTES = MAX_SIEVE_LIMIT + 1
MAX_WINDOW_FLAGS_BYTES = SEARCH_MAX - 1
INDEPENDENT_FLAG_STORAGE_BYTES = MAX_SIEVE_FLAGS_BYTES + MAX_WINDOW_FLAGS_BYTES


def _parse(values: Sequence[int] | None, input_is_null: bool,
           input_length: int | None) -> int | None:
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple))
            or not 1 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
            or any(type(value) is not int or not I64_MIN <= value <= I64_MAX
                   for value in values)):
        return None
    actual = len(values) if input_length is None else input_length
    if (type(actual) is not int or actual != len(values)
            or len(values) != MAX_VALID_INPUT_LENGTH):
        return None
    n = values[0]
    return n if 1 <= n <= MAX_N else None


def _sieve(limit: int) -> bytearray:
    flags = bytearray(b"\x01") * (limit + 1)
    if limit >= 0:
        flags[0] = 0
    if limit >= 1:
        flags[1] = 0
    divisor = 2
    while divisor <= limit // divisor:
        if flags[divisor]:
            for composite in range(divisor * divisor, limit + 1, divisor):
                flags[composite] = 0
        divisor += 1
    return flags


def _primorial(n: int) -> int:
    flags = _sieve(29)
    count = 0
    product = 1
    for candidate in range(2, 30):
        if flags[candidate]:
            product *= candidate
            count += 1
            if count == n:
                return product
    raise AssertionError("bounded small sieve did not contain ten primes")


def _fortunate_segmented(n: int) -> int:
    primorial = _primorial(n)
    low = primorial + 2
    high = primorial + SEARCH_MAX
    root = isqrt(high)
    base_flags = _sieve(root)
    window = bytearray(b"\x01") * (high - low + 1)
    for prime in range(2, root + 1):
        if not base_flags[prime]:
            continue
        first = ((low + prime - 1) // prime) * prime
        if first < prime * prime:
            first = prime * prime
        for composite in range(first, high + 1, prime):
            window[composite - low] = 0
    for offset in range(2, SEARCH_MAX + 1):
        if window[offset - 2]:
            return offset
    return -2


def expected_result(values: Sequence[int] | None,
                    input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    """Return the offset using sieve-generated prime flags, or a status sentinel."""
    n = _parse(values, input_is_null, input_length)
    return -1 if n is None else _fortunate_segmented(n)
