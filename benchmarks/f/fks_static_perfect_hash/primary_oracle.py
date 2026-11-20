"""Deterministic bounded FKS table builder for the scalar membership ABI."""

from __future__ import annotations

from collections.abc import Sequence

MAX_N = 8
MAX_Q = 8
MAX_VALID_INPUT_LENGTH = 18
MAX_PARSEABLE_INPUT_LENGTH = 19
PRIME = 257
INVALID_RESULT = -1


def _decode(values: Sequence[int] | None, input_is_null: bool,
            input_length: int | None) -> tuple[list[int], list[int]] | None:
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple))
            or len(values) < 2 or len(values) > MAX_PARSEABLE_INPUT_LENGTH
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return None
    if input_length is not None and (
            type(input_length) is not int or input_length != len(values)):
        return None
    n, q = values[:2]
    if not 0 <= n <= MAX_N or not 0 <= q <= MAX_Q:
        return None
    if len(values) != 2 + n + q:
        return None
    keys = list(values[2:2 + n])
    queries = list(values[2 + n:])
    if any(not 0 <= key < PRIME - 1 for key in keys + queries):
        return None
    if len(set(keys)) != n:
        return None
    return keys, queries


def _hash(a: int, b: int, modulus: int, key: int) -> int:
    return ((a * key + b) % PRIME) % modulus


def _first_seed(keys: list[int], bucket_count: int) -> tuple[int, int] | None:
    for a in range(1, PRIME):
        for b in range(PRIME):
            counts = [0] * bucket_count
            for key in keys:
                counts[_hash(a, b, bucket_count, key)] += 1
            if sum(count * count for count in counts) <= 4 * bucket_count:
                return a, b
    return None


def _local_seed(keys: list[int], capacity: int) -> tuple[int, int] | None:
    for a in range(1, PRIME):
        for b in range(PRIME):
            positions = {_hash(a, b, capacity, key) for key in keys}
            if len(positions) == len(keys):
                return a, b
    return None


def _build_table(keys: list[int]) -> tuple[
        tuple[int, int], list[list[int | None]], list[tuple[int, int] | None], list[int]
        ] | None:
    n = len(keys)
    if n == 0:
        return None
    first = _first_seed(keys, n)
    if first is None:
        return None
    bucket_of = [_hash(first[0], first[1], n, key) for key in keys]
    bucket_sizes = [0] * n
    for bucket in bucket_of:
        bucket_sizes[bucket] += 1
    slots: list[list[int | None]] = [[] for _ in range(n)]
    local_seeds: list[tuple[int, int] | None] = [None] * n
    for bucket in range(n):
        members = [key for key, index in zip(keys, bucket_of) if index == bucket]
        if not members:
            continue
        capacity = bucket_sizes[bucket] * bucket_sizes[bucket]
        seed = _local_seed(members, capacity)
        if seed is None:
            return None
        local_seeds[bucket] = seed
        table: list[int | None] = [None] * capacity
        for key in members:
            table[_hash(seed[0], seed[1], capacity, key)] = key
        slots[bucket] = table
    return first, slots, local_seeds, bucket_sizes


def expected_result(values: Sequence[int] | None, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    decoded = _decode(values, input_is_null, input_length)
    if decoded is None:
        return INVALID_RESULT
    keys, queries = decoded
    if not keys:
        return 0
    built = _build_table(keys)
    if built is None:
        return INVALID_RESULT
    first, slots, local_seeds, bucket_sizes = built
    result = 0
    for index, query in enumerate(queries):
        bucket = _hash(first[0], first[1], len(keys), query)
        seed = local_seeds[bucket]
        if seed is None:
            continue
        capacity = bucket_sizes[bucket] * bucket_sizes[bucket]
        position = _hash(seed[0], seed[1], capacity, query)
        if slots[bucket][position] == query:
            result |= 1 << index
    return result
