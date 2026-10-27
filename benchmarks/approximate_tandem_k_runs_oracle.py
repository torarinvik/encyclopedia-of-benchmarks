"""Primary bounded direct-window enumerator for longer-than-square K-runs."""

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
    text = list(values[2:])
    if (not 3 <= n <= MAX_TEXT or not 0 <= budget <= 8 or len(values) != n + 2
            or any(not 0 <= symbol <= 3 for symbol in text)):
        return None
    return n, budget, text


def _max_window_mismatches(text: Sequence[int], start: int, length: int, period: int) -> int:
    maximum = 0
    for window in range(length - 2 * period + 1):
        mismatches = sum(text[start + window + offset] != text[start + window + offset + period]
                         for offset in range(period))
        maximum = max(maximum, mismatches)
    return maximum


def _records(n: int, budget: int, text: Sequence[int]) -> list[tuple[int, int, int, int]]:
    records = []
    for start in range(n):
        remaining = n - start
        for period in range(1, (remaining - 1) // 2 + 1):
            for length in range(2 * period + 1, remaining + 1):
                errors = _max_window_mismatches(text, start, length, period)
                if errors <= budget:
                    records.append((start, length, period, errors))
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
