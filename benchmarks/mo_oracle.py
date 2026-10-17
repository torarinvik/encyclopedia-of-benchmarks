"""Oracle for the bounded pinned C++ Mo distinct-range-query program."""

from __future__ import annotations

from collections.abc import Sequence
import struct

MIN_ARRAY_SIZE = 1
MAX_ARRAY_SIZE = 64
MIN_QUERY_COUNT = 0
MAX_QUERY_COUNT = 64
MIN_VALUE = 0
MAX_VALUE = 255
I32_MIN = -(1 << 31)
I32_MAX = (1 << 31) - 1
MAX_INPUT_WORDS = 2 + MAX_ARRAY_SIZE + 2 * MAX_QUERY_COUNT
MAX_PARSEABLE_INPUT_WORDS = MAX_INPUT_WORDS + 1
MAX_OUTPUT_WORDS = MAX_QUERY_COUNT
MAX_OUTPUT_BYTES = 4 * MAX_OUTPUT_WORDS
INVALID_RESULT = -1
OUTPUT_ERROR = -2


def expected_output(
    values: Sequence[int] | None,
    output_capacity: int | None = None,
    output_is_null: bool = False,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> tuple[int, bytes]:
    """Return per-query distinct counts as raw little-endian signed-i32 bytes."""
    if type(output_is_null) is not bool or type(input_is_null) is not bool:
        return INVALID_RESULT, b""
    if output_capacity is not None and (
        type(output_capacity) is not int or output_capacity < 0
    ):
        return INVALID_RESULT, b""
    if input_length is not None and (
        type(input_length) is not int or input_length < 0
    ):
        return INVALID_RESULT, b""
    if input_is_null:
        if values not in (None, [], ()) or input_length is None or input_length <= 0:
            return INVALID_RESULT, b""
        return INVALID_RESULT, b""
    if values is None or not isinstance(values, (list, tuple)):
        return INVALID_RESULT, b""
    if input_length is not None and input_length != len(values):
        return INVALID_RESULT, b""
    if not 3 <= len(values) <= MAX_PARSEABLE_INPUT_WORDS:
        return INVALID_RESULT, b""
    if any(type(value) is not int or not I32_MIN <= value <= I32_MAX for value in values):
        return INVALID_RESULT, b""

    array_size = values[0]
    if not MIN_ARRAY_SIZE <= array_size <= MAX_ARRAY_SIZE:
        return INVALID_RESULT, b""
    query_count_index = 1 + array_size
    if query_count_index >= len(values):
        return INVALID_RESULT, b""
    query_count = values[query_count_index]
    if not MIN_QUERY_COUNT <= query_count <= MAX_QUERY_COUNT:
        return INVALID_RESULT, b""
    if len(values) != 2 + array_size + 2 * query_count:
        return INVALID_RESULT, b""

    array_values = values[1:query_count_index]
    if any(not MIN_VALUE <= value <= MAX_VALUE for value in array_values):
        return INVALID_RESULT, b""

    counts: list[int] = []
    query_offset = query_count_index + 1
    for query_index in range(query_count):
        left = values[query_offset + 2 * query_index]
        right = values[query_offset + 2 * query_index + 1]
        if not 1 <= left <= right <= array_size:
            return INVALID_RESULT, b""
        # Convert the source's one-based inclusive bounds to the equivalent
        # Python half-open slice. Results are kept in original query order.
        counts.append(len(set(array_values[left - 1 : right])))

    encoded = struct.pack("<" + "i" * len(counts), *counts) if counts else b""
    if len(encoded) > MAX_OUTPUT_BYTES:
        return INVALID_RESULT, b""
    if output_is_null:
        return OUTPUT_ERROR, b""
    if output_capacity is not None and output_capacity < len(encoded):
        return OUTPUT_ERROR, b""
    return len(encoded), encoded


def expected_result(values: Sequence[int] | None) -> tuple[int, bytes]:
    """Convenience entrypoint used by the benchmark workload tooling."""
    return expected_output(values)
