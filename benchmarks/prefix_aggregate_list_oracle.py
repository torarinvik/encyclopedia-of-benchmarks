"""Oracle for a bounded addition-based prefix aggregate list."""

from __future__ import annotations

import struct
from collections.abc import Sequence

MAX_INITIAL_VALUES = 64
MAX_OPERATIONS = 64
MAX_LIVE_VALUES = 128
MAX_VALUE = 1_000_000
MAX_INPUT_LENGTH = 2 + MAX_INITIAL_VALUES + 3 * MAX_OPERATIONS
MAX_PARSEABLE_INPUT_LENGTH = MAX_INPUT_LENGTH + 2
MAX_OUTPUT_BYTES = 8 * MAX_OPERATIONS
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1


def expected_output(
    values: Sequence[int],
    output_capacity: int | None = None,
    output_is_null: bool = False,
) -> tuple[int, bytes]:
    if (not isinstance(values, (list, tuple))
            or not 3 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
            or any(type(value) is not int or not I64_MIN <= value <= I64_MAX
                   for value in values)):
        return -1, b""

    initial_count = values[0]
    if not 1 <= initial_count <= MAX_INITIAL_VALUES or len(values) < initial_count + 2:
        return -1, b""

    initial_values = values[1:1 + initial_count]
    if any(not -MAX_VALUE <= value <= MAX_VALUE for value in initial_values):
        return -1, b""
    operation_count = values[1 + initial_count]
    if not 0 <= operation_count <= MAX_OPERATIONS:
        return -1, b""

    live_values = list(initial_values)
    prefixes = [live_values[0]]
    for value in live_values[1:]:
        prefixes.append(prefixes[-1] + value)

    cursor = initial_count + 2
    query_results: list[int] = []
    for _ in range(operation_count):
        if cursor >= len(values):
            return -1, b""
        operation = values[cursor]
        cursor += 1
        if operation == 0:
            if cursor >= len(values):
                return -1, b""
            value = values[cursor]
            cursor += 1
            if (not -MAX_VALUE <= value <= MAX_VALUE
                    or len(live_values) >= MAX_LIVE_VALUES):
                return -1, b""
            live_values.append(value)
            prefixes.append(prefixes[-1] + value)
        elif operation == 1:
            if len(live_values) <= 1:
                return -1, b""
            live_values.pop()
            prefixes.pop()
        elif operation == 2:
            if cursor + 1 >= len(values):
                return -1, b""
            range_from, range_to = values[cursor], values[cursor + 1]
            cursor += 2
            if not 1 <= range_from <= range_to <= len(live_values):
                return -1, b""
            if range_from == 1:
                query_results.append(prefixes[range_to - 1])
            else:
                query_results.append(prefixes[range_to - 1] - prefixes[range_from - 2])
        else:
            return -1, b""

    if cursor != len(values):
        return -1, b""

    encoded = b"".join(struct.pack("<q", result) for result in query_results)
    if type(output_is_null) is not bool:
        return -1, b""
    if output_capacity is not None and (
        type(output_capacity) is not int or output_capacity < 0
    ):
        return -1, b""
    if output_is_null or (output_capacity is not None and output_capacity < len(encoded)):
        return -2, b""
    return len(encoded), encoded
