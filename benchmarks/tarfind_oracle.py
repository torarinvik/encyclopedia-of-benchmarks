"""Oracle for the bounded Embench-IoT TAR-header filename search."""

from __future__ import annotations

from collections.abc import Sequence

MAX_RECORDS = 35
MAX_QUERIES = 5
MIN_NAME_LENGTH = 5
MAX_NAME_LENGTH = 39
MAX_INPUT_LENGTH = 2 + MAX_RECORDS * (1 + MAX_NAME_LENGTH) + MAX_QUERIES * (1 + MAX_NAME_LENGTH)
MAX_OUTPUT_BYTES = MAX_QUERIES
INVALID_RESULT = -1
OUTPUT_ERROR = -2
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1


def _decode(values: Sequence[int] | None) -> tuple[list[bytes], list[bytes]] | None:
    if (
        not isinstance(values, (list, tuple))
        or not 2 <= len(values) <= MAX_INPUT_LENGTH
        or any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values)
    ):
        return None
    record_count, query_count = values[:2]
    if not 1 <= record_count <= MAX_RECORDS or not 1 <= query_count <= MAX_QUERIES:
        return None

    position = 2
    records: list[bytes] = []
    for _ in range(record_count):
        if position >= len(values):
            return None
        name_length = values[position]
        position += 1
        if not MIN_NAME_LENGTH <= name_length <= MAX_NAME_LENGTH:
            return None
        if name_length > len(values) - position:
            return None
        name_values = values[position : position + name_length]
        if any(not 65 <= value <= 90 for value in name_values):
            return None
        records.append(bytes(name_values))
        position += name_length

    queries: list[bytes] = []
    for _ in range(query_count):
        if position >= len(values):
            return None
        name_length = values[position]
        position += 1
        if not MIN_NAME_LENGTH <= name_length <= MAX_NAME_LENGTH:
            return None
        if name_length > len(values) - position:
            return None
        name_values = values[position : position + name_length]
        if any(not 65 <= value <= 90 for value in name_values):
            return None
        queries.append(bytes(name_values))
        position += name_length
    if position != len(values):
        return None
    return records, queries


def expected_output(
    values: Sequence[int] | None,
    output_capacity: int | None = None,
    output_is_null: bool = False,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> tuple[int, bytes]:
    """Return each query's first matching archive slot, or 255 when absent."""
    if type(output_is_null) is not bool or type(input_is_null) is not bool:
        return INVALID_RESULT, b""
    if output_capacity is not None and (
        type(output_capacity) is not int or output_capacity < 0
    ):
        return INVALID_RESULT, b""
    if input_length is not None and (type(input_length) is not int or input_length < 0):
        return INVALID_RESULT, b""
    if input_is_null or values is None or not isinstance(values, (list, tuple)):
        return INVALID_RESULT, b""
    if input_length is not None and input_length != len(values):
        return INVALID_RESULT, b""

    decoded = _decode(values)
    if decoded is None:
        return INVALID_RESULT, b""
    records, queries = decoded
    output = bytes(
        next((index for index, record in enumerate(records) if record == query), 255)
        for query in queries
    )
    if output_is_null or (output_capacity is not None and output_capacity < len(output)):
        return OUTPUT_ERROR, b""
    return len(output), output
