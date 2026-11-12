"""Independent snapshot-based checker for persistent affine versions."""

from __future__ import annotations

import struct
from typing import Sequence

MODULUS = 998_244_353
N_LIMIT = 16
Q_LIMIT = 16
VALUE_LIMIT = MODULUS - 1
VALID_WORDS = 2 + N_LIMIT + 6 * Q_LIMIT
PARSEABLE_WORDS = VALID_WORDS + 1
BYTE_LIMIT = 8 * Q_LIMIT
WORKSPACE_LIMIT = BYTE_LIMIT
INTERNAL_NODE_POOL_LIMIT = 131_072


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    bad = (input_is_null or not isinstance(values, (list, tuple))
           or len(values) < 2 or len(values) > PARSEABLE_WORDS
           or any(type(v) is not int or not -(1 << 63) <= v < (1 << 63)
                  for v in values))
    if input_length is not None:
        bad = bad or type(input_length) is not int or input_length != len(values) \
            or not 0 <= input_length <= PARSEABLE_WORDS
    if bad:
        return -1, b""
    assert values is not None
    n, q = values[0], values[1]
    if not 1 <= n <= N_LIMIT or not 1 <= q <= Q_LIMIT or len(values) < 2 + n:
        return -1, b""
    base = list(values[2:2 + n])
    if any(x < 0 or x > VALUE_LIMIT for x in base):
        return -1, b""
    versions: list[list[int] | None] = []
    kinds: list[int] = []
    pending: list[tuple[int, ...]] = []
    at = 2 + n

    def earlier(ref: int, current: int) -> bool:
        return ref == -1 or (0 <= ref < current and kinds[ref] != 2)

    for index in range(q):
        if at == len(values):
            return -1, b""
        tag = values[at]
        size = {0: 6, 1: 5, 2: 4}.get(tag)
        if size is None or at + size > len(values):
            return -1, b""
        rec = tuple(values[at:at + size])
        at += size
        if tag == 0:
            _, parent, lo, hi, factor, offset = rec
            if (not earlier(parent, index) or not 0 <= lo < hi <= n
                    or not 1 <= factor < MODULUS or not 0 <= offset < MODULUS):
                return -1, b""
            versions.append(None)
        elif tag == 1:
            _, parent, donor, lo, hi = rec
            if (not earlier(parent, index) or not earlier(donor, index)
                    or not 0 <= lo < hi <= n):
                return -1, b""
            versions.append(None)
        else:
            _, ref, lo, hi = rec
            if not earlier(ref, index) or not 0 <= lo < hi <= n:
                return -1, b""
            versions.append(None)
        kinds.append(tag)
        pending.append(rec)
    if at != len(values):
        return -1, b""

    snapshots: dict[int, list[int]] = {-1: base}
    answer_values: list[int] = []
    for index, rec in enumerate(pending):
        if rec[0] == 0:
            _, parent, lo, hi, factor, offset = rec
            row = snapshots[parent][:]
            row[lo:hi] = [((factor * x + offset) % MODULUS) for x in row[lo:hi]]
            snapshots[index] = row
        elif rec[0] == 1:
            _, parent, donor, lo, hi = rec
            row = snapshots[parent][:]
            row[lo:hi] = snapshots[donor][lo:hi]
            snapshots[index] = row
        else:
            _, ref, lo, hi = rec
            answer_values.append(sum(snapshots[ref][lo:hi]) % MODULUS)

    cap = BYTE_LIMIT if capacity is None else capacity
    if (type(output_is_null) is not bool or type(cap) is not int
            or cap < 0 or output_is_null or cap < 8 * len(answer_values)):
        return -2, b""
    packed = b"".join(struct.pack("<q", value) for value in answer_values)
    return len(packed), packed
