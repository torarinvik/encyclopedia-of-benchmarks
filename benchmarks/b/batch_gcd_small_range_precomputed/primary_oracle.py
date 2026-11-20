"""Bounded batch-GCD model using linear preprocessing and factor triples."""

from __future__ import annotations

from math import isqrt

MAX_VALUE = 64
MAX_QUERIES = 64
MAX_VALID_INPUT_LENGTH = 2 + 2 * MAX_QUERIES
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_OUTPUT_BYTES = 8 * MAX_QUERIES
WORKSPACE_BYTES = 4096


def _i64(value: object) -> bool:
    return type(value) is int and -(1 << 63) <= value < (1 << 63)


def _precompute(limit: int):
    """Return least factors, three-factor representations, and gcd table."""
    least = [0] * (limit + 1)
    primes: list[int] = []
    for value in range(2, limit + 1):
        if least[value] == 0:
            least[value] = value
            primes.append(value)
        for prime in primes:
            composite = value * prime
            if composite > limit or prime > least[value]:
                break
            least[composite] = prime

    factors = [(0, 0, 0) for _ in range(limit + 1)]
    factors[1] = (1, 1, 1)
    for value in range(2, limit + 1):
        prime = least[value]
        triple = list(factors[value // prime])
        smallest = min(range(3), key=triple.__getitem__)
        triple[smallest] *= prime
        triple.sort()
        factors[value] = tuple(triple)

    small_limit = isqrt(limit)
    gcd_table = [[0] * (small_limit + 1) for _ in range(small_limit + 1)]
    for left in range(1, small_limit + 1):
        gcd_table[left][0] = left
        for right in range(1, left):
            gcd_table[left][right] = gcd_table[right][left % right]
    return factors, gcd_table, small_limit


def _pair_gcd(left: int, right: int, factors, gcd_table, small_limit: int) -> int:
    if left == 0:
        return right
    remaining = right
    result = 1
    for factor in factors[left]:
        if factor <= small_limit:
            common = gcd_table[factor][remaining % factor]
        else:
            common = factor if remaining % factor == 0 else 1
        remaining //= common
        result *= common
    return result


def _compute(limit: int, pairs: list[tuple[int, int]]) -> bytes:
    factors, gcd_table, small_limit = _precompute(limit)
    output = bytearray()
    for left, right in pairs:
        output.extend(_pair_gcd(left, right, factors, gcd_table, small_limit).to_bytes(8, "little"))
    return bytes(output)


def expected_output(values, capacity=None, output_is_null=False,
                    input_is_null=False, input_length=None):
    """Return (ABI result, output bytes) for the bounded primary method."""
    if type(output_is_null) is not bool or type(input_is_null) is not bool:
        return -1, b""
    if capacity is not None and (type(capacity) is not int or capacity < 0):
        return -1, b""
    if input_length is not None and (type(input_length) is not int or input_length < 0):
        return -1, b""
    if input_is_null or not isinstance(values, (list, tuple)):
        return -1, b""
    length = len(values)
    if not 2 <= length <= MAX_PARSEABLE_INPUT_LENGTH:
        return -1, b""
    if input_length is not None and input_length != length:
        return -1, b""
    if any(not _i64(word) for word in values):
        return -1, b""

    limit, query_count = values[0], values[1]
    if not 1 <= limit <= MAX_VALUE or not 0 <= query_count <= MAX_QUERIES:
        return -1, b""
    if length != 2 + 2 * query_count:
        return -1, b""
    pairs = []
    for index in range(query_count):
        left, right = values[2 + 2 * index:4 + 2 * index]
        if not 0 <= left <= limit or not 0 <= right <= limit:
            return -1, b""
        pairs.append((left, right))

    required = 8 * query_count
    if output_is_null or (capacity is not None and capacity < required):
        return -2, b""
    return required, _compute(limit, pairs)
