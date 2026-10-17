"""Oracle for the bounded pinned Python maxpooling function."""

from __future__ import annotations

from collections.abc import Sequence
import struct

MIN_MATRIX_SIZE = 1
MAX_MATRIX_SIZE = 16
MIN_POOL_SIZE = 1
MIN_STRIDE = 1
MAX_STRIDE = 16
MIN_PIXEL = -1_000_000
MAX_PIXEL = 1_000_000
I32_MIN = -(1 << 31)
I32_MAX = (1 << 31) - 1
MAX_INPUT_WORDS = 3 + MAX_MATRIX_SIZE * MAX_MATRIX_SIZE
MAX_PARSEABLE_INPUT_WORDS = MAX_INPUT_WORDS + 1
MAX_OUTPUT_VALUES = MAX_MATRIX_SIZE * MAX_MATRIX_SIZE
MAX_OUTPUT_BYTES = 8 * MAX_OUTPUT_VALUES
INVALID_RESULT = -1
OUTPUT_ERROR = -2


def expected_output(
    values: Sequence[int] | None,
    output_capacity: int | None = None,
    output_is_null: bool = False,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> tuple[int, bytes]:
    """Return row-major max-pooling values encoded as little-endian f64 bytes."""
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
    if not 3 <= len(values) <= MAX_PARSEABLE_INPUT_WORDS:
        return INVALID_RESULT, b""
    if any(type(value) is not int or not I32_MIN <= value <= I32_MAX for value in values):
        return INVALID_RESULT, b""

    matrix_size, pool_size, stride = values[:3]
    if not MIN_MATRIX_SIZE <= matrix_size <= MAX_MATRIX_SIZE:
        return INVALID_RESULT, b""
    if not MIN_POOL_SIZE <= pool_size <= matrix_size:
        return INVALID_RESULT, b""
    if not MIN_STRIDE <= stride <= MAX_STRIDE:
        return INVALID_RESULT, b""
    if len(values) != 3 + matrix_size * matrix_size:
        return INVALID_RESULT, b""
    pixels = values[3:]
    if any(not MIN_PIXEL <= pixel <= MAX_PIXEL for pixel in pixels):
        return INVALID_RESULT, b""

    matrix = [
        pixels[row * matrix_size : (row + 1) * matrix_size]
        for row in range(matrix_size)
    ]
    output_size = (matrix_size - pool_size) // stride + 1
    pooled: list[int] = []
    for output_row in range(output_size):
        row_start = output_row * stride
        for output_column in range(output_size):
            column_start = output_column * stride
            pooled.append(
                max(
                    matrix[row][column]
                    for row in range(row_start, row_start + pool_size)
                    for column in range(column_start, column_start + pool_size)
                )
            )

    encoded = struct.pack("<" + "d" * len(pooled), *(float(value) for value in pooled))
    if len(encoded) > MAX_OUTPUT_BYTES:
        return INVALID_RESULT, b""
    if output_is_null or (
        output_capacity is not None and output_capacity < len(encoded)
    ):
        return OUTPUT_ERROR, b""
    return len(encoded), encoded
