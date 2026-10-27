"""Primary bounded enumerator for longer-than-square K-repetition factors."""

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
    n, budget = values[0], values[1]
    if not 3 <= n <= MAX_TEXT or not 0 <= budget <= 8 or len(values) != n + 2:
        return None
    text = list(values[2:])
    if any(not 0 <= symbol <= 3 for symbol in text):
        return None
    return n, budget, text


def _records(n: int, budget: int, text: Sequence[int]) -> list[tuple[int, int, int, int]]:
    records = []
    for start in range(n):
        remaining = n - start
        for period in range(1, (remaining - 1) // 2 + 1):
            for length in range(2 * period + 1, remaining + 1):
                mismatches = 0
                for offset in range(length - period):
                    mismatches += text[start + offset] != text[start + offset + period]
                if mismatches <= budget:
                    records.append((start, length, period, mismatches))
    return records


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
    records = _records(*parsed)
    words = (len(records), *(word for record in records for word in record))
    output = b"".join(struct.pack("<q", value) for value in words)
    if output_is_null or capacity is not None and capacity < len(output):
        return -2, b""
    return len(output), output
