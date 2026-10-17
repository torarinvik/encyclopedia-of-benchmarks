"""Oracle for the bounded Lua median-heap operation trace."""

from __future__ import annotations

from bisect import insort
from collections.abc import Sequence
import struct

MAX_OPERATIONS = 256
MAX_VALID_INPUT_LENGTH = 1 + 2 * MAX_OPERATIONS
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_LIVE_VALUES = 64
MAX_OUTPUT_BYTES = 8 * MAX_OPERATIONS
INT32_MIN = -(1 << 31)
INT32_MAX = (1 << 31) - 1
INT64_MIN = -(1 << 63)
INT64_MAX = (1 << 63) - 1
NIL_SENTINEL = INT64_MIN
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
    """Return one serialized method result per operation, or an ABI error."""
    if type(output_is_null) is not bool or type(input_is_null) is not bool:
        return INVALID_RESULT, b""
    if input_is_null or values is None or not isinstance(values, (list, tuple)):
        return INVALID_RESULT, b""
    if input_length is not None and (
        type(input_length) is not int or input_length < 0 or input_length != len(values)
    ):
        return INVALID_RESULT, b""
    if not 1 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH:
        return INVALID_RESULT, b""
    if any(not _is_i64(value) for value in values):
        return INVALID_RESULT, b""

    operation_count = values[0]
    if not 0 <= operation_count <= MAX_OPERATIONS:
        return INVALID_RESULT, b""
    if len(values) > MAX_VALID_INPUT_LENGTH or len(values) != 1 + 2 * operation_count:
        return INVALID_RESULT, b""

    # A sorted reference model keeps this oracle independent from the source's
    # two-heap representation. Index (n - 1) // 2 is the lower median.
    ordered: list[int] = []
    results: list[int] = []
    position = 1
    for _ in range(operation_count):
        opcode, argument = values[position], values[position + 1]
        position += 2

        if opcode == 0:  # push(value)
            if not INT32_MIN <= argument <= INT32_MAX or len(ordered) >= MAX_LIVE_VALUES:
                return INVALID_RESULT, b""
            insort(ordered, argument)
            results.append(NIL_SENTINEL)  # Lua methods with no return yield nil.
        elif opcode == 1:  # top()
            if argument != 0:
                return INVALID_RESULT, b""
            results.append(ordered[(len(ordered) - 1) // 2] if ordered else NIL_SENTINEL)
        elif opcode == 2:  # pop()
            if argument != 0:
                return INVALID_RESULT, b""
            if ordered:
                lower_median_index = (len(ordered) - 1) // 2
                results.append(ordered.pop(lower_median_index))
            else:
                results.append(NIL_SENTINEL)
        elif opcode == 3:  # size()
            if argument != 0:
                return INVALID_RESULT, b""
            results.append(len(ordered))
        elif opcode == 4:  # empty()
            if argument != 0:
                return INVALID_RESULT, b""
            results.append(1 if not ordered else 0)
        else:
            return INVALID_RESULT, b""

    output = b"".join(struct.pack("<q", result) for result in results)
    if len(output) > MAX_OUTPUT_BYTES:
        return INVALID_RESULT, b""
    if capacity is not None and (type(capacity) is not int or capacity < 0):
        return INVALID_RESULT, b""
    if output_is_null or (capacity is not None and capacity < len(output)):
        return OUTPUT_ERROR, b""
    return len(output), output
