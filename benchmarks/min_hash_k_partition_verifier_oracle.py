"""Independent bucket-grouping verifier for DOI 573 k-partition sketches."""
from __future__ import annotations

import struct
from collections.abc import Sequence

MAX_K = 8
MAX_N = 32
MAX_INPUT_LENGTH = 2 + 2 * MAX_N
MAX_OUTPUT_BYTES = 2 * MAX_K * 8


def _parse(values: Sequence[int] | None):
    if (not isinstance(values, (list, tuple)) or len(values) < 2 or len(values) > MAX_INPUT_LENGTH
            or any(type(v) is not int or not -(1 << 63) <= v < (1 << 63) for v in values)):
        return None
    k, n = values[:2]
    if not 1 <= k <= MAX_K or not 0 <= n <= MAX_N or len(values) != 2 + 2 * n:
        return None
    groups: list[list[tuple[int, int]]] = [[] for _ in range(k)]
    for item_id in range(n):
        bucket, rank = values[2 + 2 * item_id:4 + 2 * item_id]
        if not 0 <= bucket < k or not 0 <= rank <= 1000:
            return None
        groups[bucket].append((rank, item_id))
    return groups


def _result(groups: list[list[tuple[int, int]]]) -> list[int]:
    out: list[int] = []
    for group in groups:
        if not group:
            out.extend((-1, 1001))
        else:
            rank, item_id = min(group)
            out.extend((item_id, rank))
    return out


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
    groups = None if input_is_null else _parse(values)
    if groups is None:
        return -1, b""
    payload = struct.pack("<" + "q" * (2 * len(groups)), *_result(groups))
    if output_is_null or capacity is not None and capacity < len(payload):
        return -2, b""
    return len(payload), payload
