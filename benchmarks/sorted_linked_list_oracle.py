"""Oracle for bounded insert, search, and delete on a sorted linked list."""

from __future__ import annotations

from collections.abc import Sequence
import struct

MIN_I32 = -(1 << 31)
MAX_I32 = (1 << 31) - 1
MIN_I64 = -(1 << 63)
MAX_I64 = (1 << 63) - 1
MAX_INITIAL_COUNT = 16
MAX_VALID_INPUT_LENGTH = MAX_INITIAL_COUNT + 3
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_OUTPUT_WORDS = 18
MAX_OUTPUT_BYTES = 8 * MAX_OUTPUT_WORDS
OP_INSERT = 0
OP_SEARCH = 1
OP_DELETE = 2
INVALID_RESULT = -1
OUTPUT_ERROR = -2


def _decode_input(values: Sequence[int] | None):
    if (not isinstance(values, (list, tuple))
            or not 3 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH):
        return None
    if any(type(value) is not int or not MIN_I64 <= value <= MAX_I64
           for value in values):
        return None

    count = values[0]
    if not 0 <= count <= MAX_INITIAL_COUNT or len(values) != count + 3:
        return None
    initial_values = values[1:1 + count]
    if any(not MIN_I32 <= value <= MAX_I32 for value in initial_values):
        return None
    if any(left >= right for left, right in zip(initial_values, initial_values[1:])):
        return None
    operation, key = values[1 + count], values[2 + count]
    if operation not in (OP_INSERT, OP_SEARCH, OP_DELETE):
        return None
    if not MIN_I32 <= key <= MAX_I32:
        return None
    if operation == OP_INSERT and key in initial_values:
        return None
    return list(initial_values), operation, key


def _apply(initial_values: list[int], operation: int, key: int) -> list[int]:
    if operation == OP_INSERT:
        position = 0
        while position < len(initial_values) and initial_values[position] < key:
            position += 1
        initial_values.insert(position, key)
        words = [len(initial_values), *initial_values]
    elif operation == OP_SEARCH:
        words = [int(key in initial_values)]
    else:
        try:
            position = initial_values.index(key)
        except ValueError:
            words = [0, len(initial_values), *initial_values]
        else:
            del initial_values[position]
            words = [1, len(initial_values), *initial_values]
    return words


def expected_output(
    values: Sequence[int] | None,
    capacity: int | None = None,
    output_is_null: bool = False,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> tuple[int, bytes]:
    """Return operation output as little-endian signed-i64 words or an ABI error."""
    if type(output_is_null) is not bool or type(input_is_null) is not bool:
        return INVALID_RESULT, b""
    if input_is_null or values is None or not isinstance(values, (list, tuple)):
        return INVALID_RESULT, b""
    if input_length is not None and (
        type(input_length) is not int or input_length != len(values)
    ):
        return INVALID_RESULT, b""

    decoded = _decode_input(values)
    if decoded is None:
        return INVALID_RESULT, b""
    initial_values, operation, key = decoded
    words = _apply(initial_values, operation, key)
    output = b"".join(struct.pack("<q", word) for word in words)
    if len(output) > MAX_OUTPUT_BYTES:
        return INVALID_RESULT, b""
    if capacity is not None and (type(capacity) is not int or capacity < 0):
        return INVALID_RESULT, b""
    if output_is_null or (capacity is not None and capacity < len(output)):
        return OUTPUT_ERROR, b""
    return len(output), output
