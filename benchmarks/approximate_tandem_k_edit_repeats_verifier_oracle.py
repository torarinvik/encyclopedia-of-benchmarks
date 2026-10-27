"""Independent recursive-partition verifier for bounded K-edit repeats."""

from __future__ import annotations

import struct
from collections.abc import Sequence

MAX_TEXT = 12
MAX_INPUT_LENGTH = 14
MAX_OUTPUT_BYTES = 1592


def _parse(values: Sequence[int] | None) -> tuple[int, int, list[int]] | None:
    if (not isinstance(values, (list, tuple)) or not 4 <= len(values) <= MAX_INPUT_LENGTH
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63) for value in values)):
        return None
    n, budget = values[:2]
    text = list(values[2:])
    if (not 2 <= n <= MAX_TEXT or not 0 <= budget <= 4 or len(values) != n + 2
            or any(symbol < 0 or symbol > 3 for symbol in text)):
        return None
    return n, budget, text


def _distance(a: Sequence[int], b: Sequence[int]) -> int:
    # Full matrix DP, independent of the primary oracle's in-place row update.
    table = [[0] * (len(b) + 1) for _ in range(len(a) + 1)]
    for i in range(len(a) + 1):
        table[i][0] = i
    for j in range(len(b) + 1):
        table[0][j] = j
    for i in range(1, len(a) + 1):
        for j in range(1, len(b) + 1):
            table[i][j] = min(table[i - 1][j] + 1,
                              table[i][j - 1] + 1,
                              table[i - 1][j - 1] + (a[i - 1] != b[j - 1]))
    return table[-1][-1]


def _partitions(text: Sequence[int], lo: int, hi: int):
    """Yield each ordered partition of text[lo:hi] into at least two pieces."""
    def extend(start: int, pieces: tuple[tuple[int, ...], ...]):
        if start == hi:
            if len(pieces) >= 2:
                yield pieces
            return
        for end in range(start + 1, hi + 1):
            yield from extend(end, pieces + (tuple(text[start:end]),))
    yield from extend(lo, ())


def _factor_minimum(text: Sequence[int], start: int, length: int) -> int:
    best = MAX_TEXT * MAX_TEXT
    for prefix_length in range(length + 1):
        prefix = tuple(text[start:start + prefix_length])
        for suffix_length in range(length - prefix_length + 1):
            middle_lo = start + prefix_length
            middle_hi = start + length - suffix_length
            if middle_hi - middle_lo < 2:
                continue
            suffix = tuple(text[middle_hi:start + length])
            for pieces in _partitions(text, middle_lo, middle_hi):
                first, last = pieces[0], pieces[-1]
                left = min(_distance(prefix, first[-take:] if take else ())
                           for take in range(len(first) + 1))
                right = min(_distance(last[:take], suffix)
                            for take in range(len(last) + 1))
                internal = sum(_distance(pieces[index], pieces[index + 1])
                               for index in range(len(pieces) - 1))
                best = min(best, left + internal + right)
    return best


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
    parsed = _parse(values)
    if parsed is None:
        return -1, b""
    n, budget, text = parsed
    records = [(start, length, cost)
               for start in range(n)
               for length in range(2, n - start + 1)
               if (cost := _factor_minimum(text, start, length)) <= budget]
    words = (len(records), *(word for record in records for word in record))
    output = b"".join(struct.pack("<q", word) for word in words)
    if output_is_null or capacity is not None and capacity < len(output):
        return -2, b""
    return len(output), output
