"""Oracle for the bounded TheAlgorithms/Python smoothsort wrapper."""

from __future__ import annotations

from collections.abc import Sequence
import struct

MAX_VALUES = 64
MAX_VALID_INPUT_LENGTH = 1 + MAX_VALUES
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_INPUT_LENGTH = MAX_PARSEABLE_INPUT_LENGTH
MAX_OUTPUT_VALUES = MAX_VALUES
MAX_OUTPUT_BYTES = 8 * MAX_OUTPUT_VALUES
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
    """Sort the bounded signed-i64 input or return the documented ABI error."""
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

    count = values[0]
    if not 0 <= count <= MAX_VALUES:
        return INVALID_RESULT, b""
    if len(values) > MAX_VALID_INPUT_LENGTH or len(values) != 1 + count:
        return INVALID_RESULT, b""

    # Python's sorted list is the independent reference, not a Leonardo heap.
    ordered_values = sorted(values[1:])
    output = b"".join(struct.pack("<q", value) for value in ordered_values)
    if len(output) > MAX_OUTPUT_BYTES:
        return INVALID_RESULT, b""
    if capacity is not None and (type(capacity) is not int or capacity < 0):
        return INVALID_RESULT, b""
    if output_is_null or (capacity is not None and capacity < len(output)):
        return OUTPUT_ERROR, b""
    return len(output), output
