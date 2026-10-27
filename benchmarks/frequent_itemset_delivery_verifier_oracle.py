"""Independent per-extension occurrence-set verifier for Chapter 722."""

from __future__ import annotations

import struct
from collections.abc import Sequence

MAX_INPUT_LENGTH = 69
MAX_OUTPUT_BYTES = 200


def _validated(values: Sequence[int] | None):
    if (not isinstance(values, (list, tuple)) or len(values) < 6 or len(values) > MAX_INPUT_LENGTH
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63) for value in values)):
        return None
    n, m, threshold, tail, prefix = values[:5]
    if not 1 <= n <= 8 or not 1 <= m <= 64 or not 1 <= threshold <= m or len(values) != 5 + m:
        return None
    if tail < -1 or tail >= n or prefix < 0 or prefix >= 1 << n:
        return None
    if (tail == -1 and prefix != 0) or (tail >= 0 and (not prefix & (1 << tail) or prefix >> (tail + 1))):
        return None
    rows = values[5:]
    if any(mask < 0 or mask >= 1 << n for mask in rows):
        return None
    return n, m, threshold, tail, prefix, rows


def verify(values: Sequence[int] | None) -> tuple[int, bytes]:
    parsed = _validated(values)
    if parsed is None:
        return -1, b""
    n, m, threshold, tail, prefix, rows = parsed
    records = []
    # For each possible child independently, form its exact occurrence set by
    # testing transaction containment; this does not use the delivery sweep.
    for item in range(tail + 1, n):
        child = prefix | (1 << item)
        row_ids = [row_id for row_id, transaction in enumerate(rows)
                   if transaction & child == child]
        if len(row_ids) < threshold:
            continue
        row_mask = 0
        for row_id in row_ids:
            row_mask |= 1 << row_id
        records.append((item, row_mask, len(row_ids)))
    words = [len(records)]
    for item, row_mask, support in records:
        words.extend((item, row_mask, support))
    raw = b"".join(struct.pack("<Q", word) for word in words)
    return len(raw), raw


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or capacity is not None and (type(capacity) is not int or capacity < 0)
            or input_length is not None and (type(input_length) is not int or not 0 <= input_length <= MAX_INPUT_LENGTH)
            or input_is_null and values not in (None, [], ())
            or not input_is_null and values is not None and input_length is not None and input_length != len(values)):
        return -1, b""
    if input_is_null or values is None:
        return -1, b""
    result, raw = verify(values)
    if result < 0:
        return result, raw
    if output_is_null or capacity is not None and capacity < len(raw):
        return -2, b""
    return result, raw
