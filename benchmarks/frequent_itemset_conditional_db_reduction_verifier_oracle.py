"""Independent row-wise verifier for conditional database reduction."""

from __future__ import annotations

import struct
from collections import Counter
from collections.abc import Sequence

MAX_ITEMS = 8
MAX_ROWS = 64
MAX_INPUT_LENGTH = 5 + MAX_ROWS
MAX_OUTPUT_BYTES = 8 * (1 + 2 * MAX_ROWS)
MAX_WORKSPACE_BYTES = 2048


def verify(values: Sequence[int] | None) -> tuple[int, bytes]:
    if (not isinstance(values, (list, tuple)) or not 6 <= len(values) <= MAX_INPUT_LENGTH
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return -1, b""
    n, rows, threshold, tail, prefix = values[:5]
    if not 1 <= n <= MAX_ITEMS or not 1 <= rows <= MAX_ROWS:
        return -1, b""
    if not 1 <= threshold <= rows or len(values) != rows + 5:
        return -1, b""
    if not -1 <= tail < n or prefix < 0 or prefix >= (1 << n):
        return -1, b""
    if ((tail == -1 and prefix != 0)
            or (tail >= 0 and ((prefix >> tail) & 1 == 0 or prefix >> (tail + 1) != 0))):
        return -1, b""
    transactions = values[5:]
    if any(mask < 0 or mask >= (1 << n) for mask in transactions):
        return -1, b""
    occurrence_ids = [r for r, mask in enumerate(transactions)
                      if (mask & prefix) == prefix]
    if len(occurrence_ids) < threshold:
        return -1, b""

    eligible = set()
    for item in range(tail + 1, n):
        bit = 1 << item
        support = 0
        for row_id in occurrence_ids:
            if transactions[row_id] & bit:
                support += 1
        if support >= threshold:
            eligible.add(item)

    # Build each reduced transaction independently, then count equal masks.
    multiplicities: Counter[int] = Counter()
    for row_id in occurrence_ids:
        source_mask = transactions[row_id]
        reduced_mask = 0
        if tail >= 0:
            reduced_mask |= source_mask & (1 << tail)
        for item in eligible:
            if source_mask & (1 << item):
                reduced_mask |= 1 << item
        multiplicities[reduced_mask] += 1

    words = [len(multiplicities)]
    for mask in sorted(multiplicities):
        words.extend((mask, multiplicities[mask]))
    raw = b"".join(struct.pack("<Q", word) for word in words)
    return len(raw), raw
