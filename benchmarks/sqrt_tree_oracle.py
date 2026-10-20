"""Independent brute-force oracle for the bounded sqrt-tree RMQ workload."""

from __future__ import annotations

import struct
from collections.abc import Sequence

MAX_ITEMS = 256
MAX_QUERIES = 256
MIN_VALUE = -1_000_000_000
MAX_VALUE = 1_000_000_000
MAX_VALID_INPUT_VALUES = 2 + MAX_ITEMS + 2 * MAX_QUERIES
MAX_PARSEABLE_INPUT_VALUES = MAX_VALID_INPUT_VALUES + 1
MAX_OUTPUT_BYTES = 8 * MAX_QUERIES
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1
INVALID_RESULT = -1
OUTPUT_ERROR = -2


def expected_output(
    values: Sequence[int] | None,
    output_capacity: int | None = None,
    output_is_null: bool = False,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> tuple[int, bytes]:
    """Return (byte count, LE64 minima), or the contract error and no bytes."""
    if type(input_is_null) is not bool or type(output_is_null) is not bool:
        return INVALID_RESULT, b""
    if input_is_null:
        return INVALID_RESULT, b""
    if (
        not isinstance(values, (tuple, list))
        or len(values) > MAX_PARSEABLE_INPUT_VALUES
        or any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values)
    ):
        return INVALID_RESULT, b""
    if input_length is not None and (
        type(input_length) is not int
        or not 0 <= input_length <= MAX_PARSEABLE_INPUT_VALUES
        or input_length != len(values)
    ):
        return INVALID_RESULT, b""
    if len(values) < 2:
        return INVALID_RESULT, b""

    item_count, query_count = values[0], values[1]
    if not 1 <= item_count <= MAX_ITEMS or not 0 <= query_count <= MAX_QUERIES:
        return INVALID_RESULT, b""
    if len(values) != 2 + item_count + 2 * query_count:
        return INVALID_RESULT, b""
    data = values[2 : 2 + item_count]
    if any(not MIN_VALUE <= value <= MAX_VALUE for value in data):
        return INVALID_RESULT, b""
    query_words = values[2 + item_count :]
    ranges: list[tuple[int, int]] = []
    for offset in range(0, len(query_words), 2):
        left, right = query_words[offset : offset + 2]
        if not 0 <= left <= right < item_count:
            return INVALID_RESULT, b""
        ranges.append((left, right))

    required = 8 * query_count
    if output_capacity is None:
        output_capacity = MAX_OUTPUT_BYTES
    if type(output_capacity) is not int or output_capacity < 0:
        return INVALID_RESULT, b""
    if (required > 0 and output_is_null) or output_capacity < required:
        return OUTPUT_ERROR, b""

    encoded = b"".join(struct.pack("<q", min(data[left : right + 1])) for left, right in ranges)
    return len(encoded), encoded
