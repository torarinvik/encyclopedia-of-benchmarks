"""Reference oracle for the bounded Misra-Gries frequent-item summary."""

from __future__ import annotations

import struct
from collections.abc import Sequence

MAX_K = 8
MAX_ITEMS = 64
MAX_VALUE = 15
MAX_INPUT_LENGTH = 2 + MAX_ITEMS
MAX_OUTPUT_BYTES = 8 * (1 + 2 * MAX_K)


def _parse(values: Sequence[int] | None):
    if (not isinstance(values, (list, tuple)) or len(values) < 2
            or len(values) > MAX_INPUT_LENGTH
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return None
    k, count = values[:2]
    if not 1 <= k <= MAX_K or not 0 <= count <= MAX_ITEMS or len(values) != count + 2:
        return None
    items = values[2:]
    if any(item < 0 or item > MAX_VALUE for item in items):
        return None
    return k, items


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or capacity is not None and (type(capacity) is not int or capacity < 0)
            or input_length is not None and
            (type(input_length) is not int or not 0 <= input_length <= MAX_INPUT_LENGTH)
            or input_is_null and values not in (None, [], ())
            or not input_is_null and values is not None and input_length is not None
            and input_length != len(values)):
        return -1, b""
    if input_is_null or values is None:
        return -1, b""
    parsed = _parse(values)
    if parsed is None:
        return -1, b""
    k, items = parsed
    counters: dict[int, int] = {}
    for item in items:
        if item in counters:
            counters[item] += 1
        elif len(counters) < k:
            counters[item] = 1
        else:
            counters = {candidate: count - 1
                        for candidate, count in counters.items() if count > 1}
    ordered = sorted(counters.items())
    output_values = [len(ordered)]
    for item, count in ordered:
        output_values.extend((item, count))
    output = b"".join(struct.pack("<q", value) for value in output_values)
    if output_is_null or capacity is not None and capacity < len(output):
        return -2, b""
    return len(output), output
