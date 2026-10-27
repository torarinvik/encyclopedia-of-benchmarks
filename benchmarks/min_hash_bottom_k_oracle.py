"""Deterministic supplied-rank bottom-k sketch profile for DOI 573."""
from __future__ import annotations

import struct
from collections.abc import Sequence

MAX_N = 16
MAX_K = 8
MAX_VALID_INPUT_LENGTH = 2 + 2 * MAX_N
MAX_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_OUTPUT_BYTES = 8 * (1 + 2 * MAX_K)


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
    if input_is_null or values is None or not isinstance(values, (list, tuple)):
        return -1, b""
    if len(values) < 2 or len(values) > MAX_INPUT_LENGTH or any(
            type(x) is not int or not -(1 << 63) <= x < (1 << 63) for x in values):
        return -1, b""
    n, k = values[:2]
    if not 1 <= n <= MAX_N or not 1 <= k <= MAX_K or len(values) != 2 + 2 * n:
        return -1, b""
    ranks: list[tuple[int, int]] = []
    seen: set[int] = set()
    for item in range(n):
        item_id = values[2 + 2 * item]
        rank = values[3 + 2 * item]
        if not 0 <= item_id < MAX_N or item_id in seen or not 0 <= rank <= 1000:
            return -1, b""
        seen.add(item_id)
        ranks.append((rank, item_id))
    selected = sorted(ranks)[:k]
    flat = (len(selected), *(v for rank, item in selected for v in (item, rank)))
    payload = b"".join(struct.pack("<q", x) for x in flat)
    if output_is_null or capacity is not None and capacity < len(payload):
        return -2, b""
    return len(payload), payload
