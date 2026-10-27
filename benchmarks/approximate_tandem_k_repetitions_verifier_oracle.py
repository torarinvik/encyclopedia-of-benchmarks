"""Independent prefix-mismatch verifier for K-repetition enumeration."""

from __future__ import annotations

import struct
from collections.abc import Sequence

MAX_TEXT = 24
MAX_INPUT_LENGTH = 26
MAX_OUTPUT_BYTES = 34_504


def _parse(values: Sequence[int] | None) -> tuple[int, int, list[int]] | None:
    if (not isinstance(values, (list, tuple)) or not 5 <= len(values) <= MAX_INPUT_LENGTH
            or any(type(x) is not int or not -(1 << 63) <= x < (1 << 63) for x in values)):
        return None
    n, budget = values[:2]
    symbols = list(values[2:])
    if (not 3 <= n <= MAX_TEXT or not 0 <= budget <= 8 or len(values) != n + 2
            or any(symbol < 0 or symbol > 3 for symbol in symbols)):
        return None
    return n, budget, symbols


def _encode(n: int, budget: int, text: Sequence[int]) -> bytes:
    records: list[int] = []
    for period in range(1, n // 2 + 1):
        for start in range(n):
            available = n - start
            if 2 * period >= available:
                continue
            mismatch_prefix = [0]
            for offset in range(available - period):
                mismatch_prefix.append(mismatch_prefix[-1]
                                       + (text[start + offset] != text[start + offset + period]))
            for length in range(2 * period + 1, available + 1):
                mismatches = mismatch_prefix[length - period]
                if mismatches <= budget:
                    records.extend((start, length, period, mismatches))
    # Restore the primary oracle's public order independently of its start-first traversal.
    tuples = [tuple(records[i:i + 4]) for i in range(0, len(records), 4)]
    tuples.sort(key=lambda record: (record[0], record[2], record[1]))
    words = (len(tuples), *(word for record in tuples for word in record))
    return b"".join(struct.pack("<q", value) for value in words)


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
    output = _encode(*parsed)
    if output_is_null or capacity is not None and capacity < len(output):
        return -2, b""
    return len(output), output
