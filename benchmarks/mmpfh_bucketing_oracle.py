"""Explicit equal-bucket MMPHF profile from Encyclopedia DOI 639."""
from __future__ import annotations

import struct
from collections.abc import Sequence

MAX_N = 32
MAX_Q = 32
WORD_BITS = 16
BUCKET_SIZE = 3
MAX_BUCKETS = (MAX_N + BUCKET_SIZE - 1) // BUCKET_SIZE
MAX_VALID_INPUT_LENGTH = 2 + MAX_N + MAX_Q
MAX_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH
MAX_OUTPUT_WORDS = 3 + MAX_N + 3 * MAX_BUCKETS + MAX_Q
MAX_OUTPUT_BYTES = MAX_OUTPUT_WORDS * 8


def _parse(values: Sequence[int] | None):
    if (not isinstance(values, (list, tuple)) or not 3 <= len(values) <= MAX_INPUT_LENGTH
            or any(type(x) is not int or not -(1 << 63) <= x < (1 << 63) for x in values)):
        return None
    n, q = values[:2]
    if not 1 <= n <= MAX_N or not 1 <= q <= MAX_Q or len(values) != 2 + n + q:
        return None
    keys = tuple(values[2:2 + n])
    queries = tuple(values[2 + n:])
    if any(not 0 <= x < (1 << WORD_BITS) for x in keys + queries):
        return None
    if any(keys[i - 1] >= keys[i] for i in range(1, n)):
        return None
    key_index = {key: i for i, key in enumerate(keys)}
    if any(query not in key_index for query in queries):
        return None
    return keys, queries, key_index


def _lcp(a: int, b: int) -> int:
    xor = a ^ b
    if xor == 0:
        return WORD_BITS
    count = 0
    while count < WORD_BITS and ((a >> (WORD_BITS - 1 - count)) & 1) == ((b >> (WORD_BITS - 1 - count)) & 1):
        count += 1
    return count


def _profile(keys: tuple[int, ...], queries: tuple[int, ...], key_index: dict[int, int]) -> list[int]:
    bucket_count = (len(keys) + BUCKET_SIZE - 1) // BUCKET_SIZE
    lengths: list[int] = []
    prefixes: list[int] = []
    d0: list[int] = []
    for bucket in range(bucket_count):
        start = bucket * BUCKET_SIZE
        end = min(start + BUCKET_SIZE, len(keys))
        length = WORD_BITS if end - start == 1 else _lcp(keys[start], keys[end - 1])
        prefix = keys[start] >> (WORD_BITS - length) if length else 0
        lengths.append(length)
        prefixes.append(prefix)
        d0.extend([length] * (end - start))
    ranks: list[int] = []
    for query in queries:
        pos = key_index[query]
        length = d0[pos]
        prefix = query >> (WORD_BITS - length) if length else 0
        bucket = next(i for i, item in enumerate(zip(lengths, prefixes)) if item == (length, prefix))
        bucket_start = bucket * BUCKET_SIZE
        local_ordinal = pos - bucket_start
        ranks.append(bucket_start + local_ordinal)
    return [len(keys), bucket_count, len(queries), *d0,
            *(word for b in range(bucket_count) for word in (lengths[b], prefixes[b], b)), *ranks]


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or capacity is not None and (type(capacity) is not int or capacity < 0)
            or input_length is not None and (type(input_length) is not int or input_length < 0)
            or input_is_null and values not in (None, [], ())
            or not input_is_null and values is not None and input_length is not None
            and input_length != len(values)):
        return -1, b""
    parsed = None if input_is_null else _parse(values)
    if parsed is None:
        return -1, b""
    keys, queries, key_index = parsed
    words = _profile(keys, queries, key_index)
    payload = struct.pack("<" + "q" * len(words), *words)
    if output_is_null or capacity is not None and capacity < len(payload):
        return -2, b""
    return len(payload), payload
