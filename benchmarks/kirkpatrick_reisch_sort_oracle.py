"""Oracle for the bounded Kirkpatrick-Reisch block-and-heap sorting trace."""

from __future__ import annotations

from collections.abc import Sequence
import heapq
import math
import struct

MAX_ELEMENTS = 256
MAX_VALID_INPUT_LENGTH = MAX_ELEMENTS + 1
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_OUTPUT_BYTES = MAX_ELEMENTS * 8
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1
INVALID_RESULT = -1
OUTPUT_ERROR = -2


class InvalidInput(ValueError):
    """Raised when an input does not match the bounded sorting contract."""


def sort_values(values: Sequence[int]) -> list[int]:
    """Apply floor-sqrt blocks and heap-merge their sorted contents."""
    if not isinstance(values, (list, tuple)):
        raise InvalidInput("input values must be a list or tuple")
    if not 0 <= len(values) <= MAX_ELEMENTS:
        raise InvalidInput("element count is outside the supported range")
    if any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values):
        raise InvalidInput("elements must be signed 64-bit integers")
    count = len(values)
    if count <= 1:
        return list(values)

    block_size = math.isqrt(count)
    blocks = [list(values[index : index + block_size]) for index in range(0, count, block_size)]
    for block in blocks:
        block.sort()
    heap = [(block[0], block_index, 0) for block_index, block in enumerate(blocks) if block]
    heapq.heapify(heap)
    output: list[int] = []
    while heap:
        value, block_index, element_index = heapq.heappop(heap)
        output.append(value)
        next_index = element_index + 1
        if next_index < len(blocks[block_index]):
            heapq.heappush(heap, (blocks[block_index][next_index], block_index, next_index))
    return output


def expected_output(
    values: Sequence[int] | None,
    output_capacity: int | None = None,
    output_is_null: bool = False,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> tuple[int, bytes]:
    """Return little-endian sorted i64 output and the ABI result or error."""
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
    if not 1 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH:
        return INVALID_RESULT, b""
    if input_length is not None and input_length != len(values):
        return INVALID_RESULT, b""
    if any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values):
        return INVALID_RESULT, b""

    raw_count = values[0]
    if type(raw_count) is not int or not 0 <= raw_count <= MAX_ELEMENTS:
        return INVALID_RESULT, b""
    if len(values) != raw_count + 1:
        return INVALID_RESULT, b""
    try:
        sorted_values = sort_values(values[1:])
    except InvalidInput:
        return INVALID_RESULT, b""
    encoded = b"".join(struct.pack("<q", value) for value in sorted_values)
    if output_is_null or (output_capacity is not None and output_capacity < len(encoded)):
        return OUTPUT_ERROR, b""
    return len(encoded), encoded
