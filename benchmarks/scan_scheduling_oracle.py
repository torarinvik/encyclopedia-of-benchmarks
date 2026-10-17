"""Oracle for the bounded pinned Java SCAN disk-scheduling trace."""

from __future__ import annotations

from collections.abc import Sequence
import struct

MIN_DISK_SIZE = 1
MAX_DISK_SIZE = 256
MAX_REQUEST_COUNT = 64
MAX_INPUT_LENGTH = 4 + MAX_REQUEST_COUNT
MAX_OUTPUT_BYTES = 4 * (MAX_REQUEST_COUNT + 1)
I32_MIN = -(1 << 31)
I32_MAX = (1 << 31) - 1
INVALID_RESULT = -1
OUTPUT_ERROR = -2


def expected_output(
    values: Sequence[int] | None,
    output_capacity: int | None = None,
    output_is_null: bool = False,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> tuple[int, bytes]:
    """Return the service order as raw little-endian signed-i32 values."""
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
    if not 4 <= len(values) <= MAX_INPUT_LENGTH:
        return INVALID_RESULT, b""
    if any(type(value) is not int or not I32_MIN <= value <= I32_MAX for value in values):
        return INVALID_RESULT, b""

    disk_size, head_position, direction, request_count = values[:4]
    if not MIN_DISK_SIZE <= disk_size <= MAX_DISK_SIZE:
        return INVALID_RESULT, b""
    if not 0 <= head_position < disk_size or direction not in (0, 1):
        return INVALID_RESULT, b""
    if not 0 <= request_count <= MAX_REQUEST_COUNT:
        return INVALID_RESULT, b""
    if len(values) != 4 + request_count:
        return INVALID_RESULT, b""

    requests = values[4:]
    if any(not 0 <= request < disk_size for request in requests):
        return INVALID_RESULT, b""

    if not requests:
        ordered: list[int] = []
    else:
        left = sorted(request for request in requests if request < head_position)
        right = sorted(request for request in requests if request >= head_position)
        if direction == 1:
            ordered = right + [disk_size - 1] + list(reversed(left))
        else:
            ordered = list(reversed(left)) + [0] + right

    encoded = struct.pack("<" + "i" * len(ordered), *ordered) if ordered else b""
    if len(encoded) > MAX_OUTPUT_BYTES:
        return INVALID_RESULT, b""
    if output_is_null or (
        output_capacity is not None and output_capacity < len(encoded)
    ):
        return OUTPUT_ERROR, b""
    return len(encoded), encoded
