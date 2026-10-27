"""Independent streaming insertion model for DOI 573 bottom-k sketches."""
from __future__ import annotations

import struct
from collections.abc import Sequence


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
    if len(values) < 2 or len(values) > 35 or any(
            type(x) is not int or not -(1 << 63) <= x < (1 << 63) for x in values):
        return -1, b""
    n, k = values[0], values[1]
    if not 1 <= n <= 16 or not 1 <= k <= 8 or len(values) != 2 + 2 * n:
        return -1, b""
    ids: set[int] = set()
    sketch: list[tuple[int, int]] = []
    # Process records as source insertions. The insertion rule only retains a
    # candidate when the sketch has space or its rank beats the current τ_k.
    for index in range(n):
        item_id, rank = values[2 + 2 * index:4 + 2 * index]
        if not 0 <= item_id < 16 or item_id in ids or not 0 <= rank <= 1000:
            return -1, b""
        ids.add(item_id)
        candidate = (rank, item_id)
        if len(sketch) < k:
            sketch.append(candidate)
            sketch.sort()
        elif candidate < sketch[-1]:
            sketch[-1] = candidate
            sketch.sort()
    flat = (len(sketch), *(v for rank, item_id in sketch for v in (item_id, rank)))
    payload = struct.pack("<" + "q" * len(flat), *flat)
    if output_is_null or capacity is not None and capacity < len(payload):
        return -2, b""
    return len(payload), payload
