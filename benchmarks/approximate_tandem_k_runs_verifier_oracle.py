"""Independent prefix-sum verifier for the K-run window condition."""

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


def _window_max(text: Sequence[int], start: int, factor_length: int, period: int) -> int:
    differences = [int(text[start + i] != text[start + i + period])
                   for i in range(factor_length - period)]
    prefix = [0]
    for difference in differences:
        prefix.append(prefix[-1] + difference)
    return max(prefix[window + period] - prefix[window]
               for window in range(factor_length - 2 * period + 1))


def _encode(n: int, budget: int, text: Sequence[int]) -> bytes:
    # Traverse period-first, then reorder records by the package's public order.
    records: list[tuple[int, int, int, int]] = []
    for period in range(1, n // 2 + 1):
        for start in range(n):
            remaining = n - start
            if 2 * period >= remaining:
                continue
            for length in range(2 * period + 1, remaining + 1):
                errors = _window_max(text, start, length, period)
                if errors <= budget:
                    records.append((start, length, period, errors))
    records.sort(key=lambda record: (record[0], record[2], record[1]))
    words = (len(records), *(word for record in records for word in record))
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
