"""Independent direct-table verifier for the bounded DOI 639 profile."""
from __future__ import annotations

import struct
from collections.abc import Sequence

MAX_N = 32
MAX_Q = 32
BITS = 16
BUCKET = 3
MAX_INPUT_LENGTH = 2 + MAX_N + MAX_Q
MAX_OUTPUT_BYTES = (3 + MAX_N + 3 * ((MAX_N + BUCKET - 1) // BUCKET) + MAX_Q) * 8


def _decode(values: Sequence[int] | None):
    if (not isinstance(values, (list, tuple)) or len(values) < 3 or len(values) > MAX_INPUT_LENGTH
            or any(type(x) is not int or not -(1 << 63) <= x < (1 << 63) for x in values)):
        return None
    n, q = values[0], values[1]
    if not 1 <= n <= MAX_N or not 1 <= q <= MAX_Q or len(values) != 2 + n + q:
        return None
    keys = list(values[2:2 + n])
    queries = list(values[2 + n:])
    if any(not 0 <= x < 1 << BITS for x in keys + queries):
        return None
    if keys != sorted(set(keys)) or any(x not in set(keys) for x in queries):
        return None
    return keys, queries


def _common_prefix_length(group: list[int]) -> int:
    words = [f"{x:016b}" for x in group]
    prefix = 0
    for chars in zip(*words):
        if len(set(chars)) != 1:
            break
        prefix += 1
    return prefix


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
    decoded = None if input_is_null else _decode(values)
    if decoded is None:
        return -1, b""
    keys, queries = decoded
    groups = [keys[i:i + BUCKET] for i in range(0, len(keys), BUCKET)]
    delimiters: list[tuple[int, int, int]] = []
    key_to_d0: dict[int, int] = {}
    for bucket_id, group in enumerate(groups):
        prefix_len = _common_prefix_length(group)
        prefix_value = group[0] >> (BITS - prefix_len) if prefix_len else 0
        delimiters.append((prefix_len, prefix_value, bucket_id))
        for key in group:
            key_to_d0[key] = prefix_len
    ranks: list[int] = []
    for query in queries:
        prefix_len = key_to_d0[query]
        prefix_value = query >> (BITS - prefix_len) if prefix_len else 0
        bucket_id = next(b for length, prefix, b in delimiters
                         if (length, prefix) == (prefix_len, prefix_value))
        local_ordinal = groups[bucket_id].index(query)
        bucket_start = bucket_id * BUCKET
        ranks.append(bucket_start + local_ordinal)
    output = [len(keys), len(groups), len(queries),
              *(key_to_d0[key] for key in keys),
              *(word for row in delimiters for word in row), *ranks]
    payload = struct.pack("<" + "q" * len(output), *output)
    if output_is_null or capacity is not None and capacity < len(payload):
        return -2, b""
    return len(payload), payload
