"""Primary streaming-update model for the DOI 573 k-partition sketch."""
from __future__ import annotations

import struct
from collections.abc import Sequence

MAX_K = 8
MAX_N = 32
MAX_RANK = 1000
EMPTY_RANK = MAX_RANK + 1
MAX_INPUT_LENGTH = 2 + 2 * MAX_N
MAX_OUTPUT_BYTES = 2 * MAX_K * 8


def _decode(values: Sequence[int] | None):
    if (not isinstance(values, (list, tuple)) or not 2 <= len(values) <= MAX_INPUT_LENGTH
            or any(type(x) is not int or not -(1 << 63) <= x < (1 << 63) for x in values)):
        return None
    k, n = values[:2]
    if not 1 <= k <= MAX_K or not 0 <= n <= MAX_N or len(values) != 2 + 2 * n:
        return None
    items = []
    for item_id in range(n):
        bucket, rank = values[2 + 2 * item_id:4 + 2 * item_id]
        if not 0 <= bucket < k or not 0 <= rank <= MAX_RANK:
            return None
        items.append((bucket, rank, item_id))
    return k, items


def _compute(k: int, items: list[tuple[int, int, int]]) -> list[int]:
    best: list[tuple[int, int] | None] = [None] * k
    for bucket, rank, item_id in items:
        candidate = (rank, item_id)
        if best[bucket] is None or candidate < best[bucket]:
            best[bucket] = candidate
    words: list[int] = []
    for choice in best:
        if choice is None:
            words.extend((-1, EMPTY_RANK))
        else:
            rank, item_id = choice
            words.extend((item_id, rank))
    return words


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
    words = _compute(*decoded)
    payload = struct.pack("<" + "q" * len(words), *words)
    if output_is_null or capacity is not None and capacity < len(payload):
        return -2, b""
    return len(payload), payload
