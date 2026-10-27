"""One-pass child-occurrence delivery oracle for Chapter 722."""

from __future__ import annotations

import struct
from collections.abc import Sequence

MAX_INPUT_LENGTH = 69
MAX_OUTPUT_BYTES = 200


def _parse(values: Sequence[int] | None):
    if (not isinstance(values, (list, tuple)) or not 6 <= len(values) <= MAX_INPUT_LENGTH
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63) for value in values)):
        return None
    item_count, row_count, minimum, tail, prefix = values[:5]
    if not 1 <= item_count <= 8 or not 1 <= row_count <= 64:
        return None
    if not 1 <= minimum <= row_count or len(values) != 5 + row_count:
        return None
    if not -1 <= tail < item_count or prefix < 0 or prefix >= (1 << item_count):
        return None
    if ((tail == -1 and prefix != 0)
            or (tail >= 0 and (prefix & (1 << tail) == 0 or prefix >> (tail + 1) != 0))):
        return None
    transactions = values[5:]
    if any(row < 0 or row >= (1 << item_count) for row in transactions):
        return None
    return item_count, row_count, minimum, tail, prefix, transactions


def evaluate(values: Sequence[int] | None) -> tuple[int, bytes]:
    parsed = _parse(values)
    if parsed is None:
        return -1, b""
    item_count, row_count, minimum, tail, prefix, transactions = parsed
    occurrence_rows = [0] * item_count
    supports = [0] * item_count

    # Chapter Delivery: visit each row in Occ(P) once, then deliver that row
    # to every extension item it contains beyond tail(P).
    for row_id, transaction in enumerate(transactions):
        if transaction & prefix != prefix:
            continue
        remaining = transaction >> (tail + 1)
        item = tail + 1
        while remaining:
            if remaining & 1:
                occurrence_rows[item] |= 1 << row_id
                supports[item] += 1
            remaining >>= 1
            item += 1

    records = [(item, occurrence_rows[item], supports[item])
               for item in range(tail + 1, item_count) if supports[item] >= minimum]
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
    result, raw = evaluate(values)
    if result < 0:
        return result, raw
    if output_is_null or capacity is not None and capacity < len(raw):
        return -2, b""
    return result, raw
