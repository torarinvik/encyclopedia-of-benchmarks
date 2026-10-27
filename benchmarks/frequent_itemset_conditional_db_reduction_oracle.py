"""Clean-room oracle for Chapter 722's LCM database-reduction transform."""

from __future__ import annotations

import struct
from collections.abc import Sequence

MAX_ITEMS = 8
MAX_ROWS = 64
MAX_INPUT_LENGTH = 5 + MAX_ROWS
MAX_OUTPUT_BYTES = 8 * (1 + 2 * MAX_ROWS)
MAX_WORKSPACE_BYTES = 2048


def _parse(values: Sequence[int] | None):
    if (not isinstance(values, (list, tuple))
            or not 6 <= len(values) <= MAX_INPUT_LENGTH
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return None
    item_count, row_count, minimum, tail, prefix = values[:5]
    if not 1 <= item_count <= MAX_ITEMS or not 1 <= row_count <= MAX_ROWS:
        return None
    if not 1 <= minimum <= row_count or len(values) != 5 + row_count:
        return None
    if not -1 <= tail < item_count or prefix < 0 or prefix >= (1 << item_count):
        return None
    if ((tail == -1 and prefix != 0)
            or (tail >= 0 and (prefix & (1 << tail) == 0
                              or prefix >> (tail + 1) != 0))):
        return None
    transactions = values[5:]
    if any(mask < 0 or mask >= (1 << item_count) for mask in transactions):
        return None
    selected = [mask for mask in transactions if mask & prefix == prefix]
    if len(selected) < minimum:
        return None
    return item_count, row_count, minimum, tail, prefix, transactions, selected


def evaluate(values: Sequence[int] | None) -> tuple[int, bytes]:
    parsed = _parse(values)
    if parsed is None:
        return -1, b""
    item_count, _, minimum, tail, prefix, transactions, selected = parsed

    # First identify frequent one-item extensions of P from Occ(P).
    keep = 0 if tail < 0 else 1 << tail
    for item in range(tail + 1, item_count):
        bit = 1 << item
        support = sum(1 for row in selected if row & bit)
        if support >= minimum:
            keep |= bit

    # Then form the conditional rows, remove items below tail(P) and the
    # infrequent extensions, and coalesce identical rows by multiplicity.
    reduced: dict[int, int] = {}
    below_tail = (1 << tail) - 1 if tail > 0 else 0
    for row in selected:
        reduced_row = row & ~below_tail & keep
        reduced[reduced_row] = reduced.get(reduced_row, 0) + 1

    words = [len(reduced)]
    for mask, multiplicity in sorted(reduced.items()):
        words.extend((mask, multiplicity))
    raw = b"".join(struct.pack("<Q", word) for word in words)
    return len(raw), raw


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or capacity is not None and (type(capacity) is not int or capacity < 0)
            or input_length is not None and (type(input_length) is not int
                                             or not 0 <= input_length <= MAX_INPUT_LENGTH)
            or input_is_null and values not in (None, [], ())
            or not input_is_null and values is not None and input_length is not None
            and input_length != len(values)):
        return -1, b""
    if input_is_null or values is None:
        return -1, b""
    result, raw = evaluate(values)
    if result < 0:
        return result, raw
    if output_is_null or capacity is not None and capacity < len(raw):
        return -2, b""
    return result, raw
