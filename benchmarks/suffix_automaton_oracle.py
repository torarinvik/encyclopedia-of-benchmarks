"""Oracle for the bounded TheAlgorithms/Python suffix-automaton trace."""

from __future__ import annotations

from collections.abc import Sequence
import struct

MAX_TEXT_LENGTH = 256
MAX_QUERY_COUNT = 128
MAX_PATTERN_LENGTH = 256
MIN_ASCII = 0
MAX_ASCII = 127
MAX_VALID_INPUT_LENGTH = 1 + MAX_TEXT_LENGTH + 1 + MAX_QUERY_COUNT * (2 + MAX_PATTERN_LENGTH)
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_INPUT_LENGTH = MAX_PARSEABLE_INPUT_LENGTH
OUTPUT_BYTES_PER_QUERY = 9
MAX_OUTPUT_BYTES = OUTPUT_BYTES_PER_QUERY * MAX_QUERY_COUNT
INT64_MIN = -(1 << 63)
INT64_MAX = (1 << 63) - 1
INVALID_RESULT = -1
OUTPUT_ERROR = -2


def _is_i64(value: object) -> bool:
    return type(value) is int and INT64_MIN <= value <= INT64_MAX


def expected_output(
    values: Sequence[int] | None,
    capacity: int | None = None,
    output_is_null: bool = False,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> tuple[int, bytes]:
    """Return tagged query records or the documented byte-output ABI error."""
    if type(output_is_null) is not bool or type(input_is_null) is not bool:
        return INVALID_RESULT, b""
    if input_is_null or values is None or not isinstance(values, (list, tuple)):
        return INVALID_RESULT, b""
    if input_length is not None and (
        type(input_length) is not int
        or input_length < 0
        or input_length != len(values)
    ):
        return INVALID_RESULT, b""
    if not 1 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH:
        return INVALID_RESULT, b""
    if any(not _is_i64(value) for value in values):
        return INVALID_RESULT, b""

    text_length = values[0]
    if not 1 <= text_length <= MAX_TEXT_LENGTH:
        return INVALID_RESULT, b""
    query_count_index = 1 + text_length
    if query_count_index >= len(values):
        return INVALID_RESULT, b""
    text_values = values[1:query_count_index]
    if any(not MIN_ASCII <= value <= MAX_ASCII for value in text_values):
        return INVALID_RESULT, b""
    text = bytes(text_values).decode("ascii")

    query_count = values[query_count_index]
    if not 0 <= query_count <= MAX_QUERY_COUNT:
        return INVALID_RESULT, b""
    cursor = query_count_index + 1
    queries: list[tuple[int, str]] = []
    for _ in range(query_count):
        if cursor + 2 > len(values):
            return INVALID_RESULT, b""
        opcode, pattern_length = values[cursor], values[cursor + 1]
        cursor += 2
        if opcode not in (0, 1, 2):
            return INVALID_RESULT, b""
        if not 0 <= pattern_length <= MAX_PATTERN_LENGTH:
            return INVALID_RESULT, b""
        if opcode == 2 and pattern_length != 0:
            return INVALID_RESULT, b""
        if cursor + pattern_length > len(values):
            return INVALID_RESULT, b""
        pattern_values = values[cursor : cursor + pattern_length]
        cursor += pattern_length
        if any(not MIN_ASCII <= value <= MAX_ASCII for value in pattern_values):
            return INVALID_RESULT, b""
        queries.append((opcode, bytes(pattern_values).decode("ascii")))

    if cursor != len(values):
        return INVALID_RESULT, b""
    if len(values) > MAX_VALID_INPUT_LENGTH:
        return INVALID_RESULT, b""

    distinct_count: int | None = None
    output_parts: list[bytes] = []
    for opcode, pattern in queries:
        if opcode == 0:
            result = int(pattern in text)
        elif opcode == 1:
            if not pattern:
                # The pinned SAM propagates one marker per text position to
                # the root state, so its empty-pattern result is len(text).
                result = len(text)
            else:
                result = sum(
                    text.startswith(pattern, start)
                    for start in range(len(text) - len(pattern) + 1)
                )
        else:
            if distinct_count is None:
                distinct_count = len(
                    {
                        text[start:end]
                        for start in range(len(text))
                        for end in range(start + 1, len(text) + 1)
                    }
                )
            result = distinct_count
        output_parts.append(bytes((opcode,)) + struct.pack("<q", result))

    output = b"".join(output_parts)
    if len(output) > MAX_OUTPUT_BYTES:
        return INVALID_RESULT, b""
    if capacity is not None and (type(capacity) is not int or capacity < 0):
        return INVALID_RESULT, b""
    # Null output is an error even when query_count is zero and no bytes are
    # needed; a nonnull zero-capacity buffer is valid for that empty result.
    if output_is_null or (capacity is not None and capacity < len(output)):
        return OUTPUT_ERROR, b""
    return len(output), output
