"""Oracle for the bounded public-operation trace of the pinned C++ 2-3-4 tree."""

from __future__ import annotations

from collections.abc import Sequence
import struct

MAX_OPERATIONS = 128
MAX_VALID_INPUT_LENGTH = 1 + 2 * MAX_OPERATIONS
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_OUTPUT_WORDS = 2 + MAX_OPERATIONS
MAX_OUTPUT_BYTES = MAX_OUTPUT_WORDS * 8
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1
INVALID_RESULT = -1
OUTPUT_ERROR = -2


class InvalidInput(ValueError):
    """Raised when an operation trace falls outside the benchmark contract."""


def _parse(values: Sequence[int]) -> tuple[list[tuple[int, int]], int]:
    if not isinstance(values, (list, tuple)):
        raise InvalidInput("input must be a list or tuple")
    if not 1 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH:
        raise InvalidInput("input length is outside the parseable range")
    if any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values):
        raise InvalidInput("input words must be signed 64-bit integers")
    operation_count = values[0]
    if not 0 <= operation_count <= MAX_OPERATIONS or len(values) != 1 + 2 * operation_count:
        raise InvalidInput("operation count or framing is invalid")
    operations: list[tuple[int, int]] = []
    for index in range(operation_count):
        operation = values[1 + 2 * index]
        key = values[2 + 2 * index]
        if operation not in (0, 1):
            raise InvalidInput("operation must be insert (0) or remove (1)")
        operations.append((operation, key))
    return operations, operation_count


def expected_output(
    values: Sequence[int] | None,
    output_capacity: int | None = MAX_OUTPUT_BYTES,
    output_is_null: bool = False,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> tuple[int, bytes]:
    """Return remove booleans and final sorted keys as little-endian i64 bytes."""
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
    if input_is_null or values is None or not isinstance(values, (list, tuple)):
        return INVALID_RESULT, b""
    if input_length is not None and input_length != len(values):
        return INVALID_RESULT, b""
    try:
        operations, _ = _parse(values)
    except InvalidInput:
        return INVALID_RESULT, b""

    items: set[int] = set()
    remove_results: list[int] = []
    for operation, key in operations:
        if operation == 0:
            items.add(key)
        else:
            existed = key in items
            remove_results.append(1 if existed else 0)
            items.discard(key)
    sorted_items = sorted(items)
    words = [len(remove_results), *remove_results, len(sorted_items), *sorted_items]
    encoded = b"".join(struct.pack("<q", word) for word in words)
    if output_is_null or (output_capacity is not None and output_capacity < len(encoded)):
        return OUTPUT_ERROR, b""
    return len(encoded), encoded
