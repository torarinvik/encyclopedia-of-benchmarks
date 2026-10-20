"""Oracle for the bounded two-dimensional Morton point ordering benchmark."""

from __future__ import annotations

from collections.abc import Sequence

MAX_POINTS = 256
MAX_COORDINATE = 65535
MAX_INPUT_LENGTH = 1 + 2 * MAX_POINTS
MAX_PARSEABLE_INPUT_LENGTH = MAX_INPUT_LENGTH
MAX_OUTPUT_BYTES = 8 * MAX_POINTS
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1
SIZE_T_MAX = (1 << 64) - 1
INVALID_RESULT = -1
OUTPUT_ERROR = -2


def _morton_code(x: int, y: int) -> int:
    code = 0
    for bit in range(16):
        code |= ((x >> bit) & 1) << (2 * bit)
        code |= ((y >> bit) & 1) << (2 * bit + 1)
    return code


def expected_output(
    values: Sequence[int],
    output_capacity: int | None = None,
    output_is_null: bool = False,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> tuple[int, bytes]:
    """Return the result code and little-endian sorted original point indices."""
    if input_length is None:
        declared_length = len(values) if isinstance(values, (list, tuple)) else -1
    elif type(input_length) is int and input_length >= 0:
        declared_length = input_length
    else:
        return INVALID_RESULT, b""

    if (not isinstance(values, (list, tuple))
            or len(values) > MAX_PARSEABLE_INPUT_LENGTH
            or any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values)
            or type(input_is_null) is not bool
            or type(output_is_null) is not bool
            or (input_is_null and (len(values) != 0 or not 1 <= declared_length <= MAX_INPUT_LENGTH))
            or (not input_is_null and declared_length != len(values))
            or declared_length > MAX_INPUT_LENGTH):
        return INVALID_RESULT, b""
    if input_is_null or declared_length < 3:
        return INVALID_RESULT, b""

    raw_count = values[0]
    if not 1 <= raw_count <= MAX_POINTS or declared_length != 1 + 2 * raw_count:
        return INVALID_RESULT, b""
    points: list[tuple[int, int]] = []
    for index in range(raw_count):
        x, y = values[1 + 2 * index], values[2 + 2 * index]
        if not 0 <= x <= MAX_COORDINATE or not 0 <= y <= MAX_COORDINATE:
            return INVALID_RESULT, b""
        points.append((x, y))

    if (output_capacity is not None
            and (type(output_capacity) is not int or not 0 <= output_capacity <= SIZE_T_MAX)):
        return INVALID_RESULT, b""
    order = sorted(range(raw_count), key=lambda index: (_morton_code(*points[index]), index))
    output = b"".join(index.to_bytes(8, byteorder="little", signed=True) for index in order)
    if output and (output_is_null or
                   (output_capacity is not None and output_capacity < len(output))):
        return OUTPUT_ERROR, b""
    return len(output), output
