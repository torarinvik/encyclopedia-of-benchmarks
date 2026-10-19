"""Independent oracle for the bounded VersaBench blocked matrix multiply."""

from __future__ import annotations

import struct
from collections.abc import Sequence

MAX_SIZE = 128
SOURCE_SIZE = 1024
MAX_INPUT_LENGTH = 3
MAX_OUTPUT_BYTES = 29
INVALID_RESULT = -1
OUTPUT_ERROR = -2
MASK32 = 0xFFFF_FFFF


def _f32(value: float) -> float:
    """Round once to IEEE-754 binary32, as each source float assignment does."""
    return struct.unpack("<f", struct.pack("<f", value))[0]


def _next_random(state: int) -> tuple[int, int]:
    state = (state * 1_664_525 + 1_013_904_223) & MASK32
    return state, (state >> 16) & 0x7FFF


def _matrices(size: int) -> tuple[list[float], list[float]]:
    """Construct the used prefix exactly as the fixed 1024-wide source does."""
    a = [0.0] * (size * size)
    b = [0.0] * (size * size)
    state = 1
    # The source initializes every column in each active row, even though the
    # bounded operation only multiplies the leading size-by-size submatrix.
    for row in range(size):
        for column in range(SOURCE_SIZE):
            state, random_a = _next_random(state)
            state, random_b = _next_random(state)
            if column < size:
                shift_a = (column - row) & 31
                shift_b = (row + column) & 31
                a[row * size + column] = float((random_a >> shift_a) & 0xF)
                b[row * size + column] = float((random_b << shift_b) & 0xF)
    return a, b


def _source_sum(size: int, block: int) -> int:
    a, b = _matrices(size)
    c = [0.0] * (size * size)

    # Use a conventional per-cell reference multiplication, independent of the
    # ports' source-ordered block traversal. Integer products and these bounded
    # per-cell sums are exact in binary32, so the k order gives the same cells.
    for i in range(size):
        for j in range(size):
            cell = i * size + j
            for k in range(size):
                c[cell] = _f32(c[cell] + a[i * size + k] * b[k * size + j])

    total = 0.0
    for outer_i in range(0, size, block):
        for outer_j in range(0, size, block):
            subtotal = 0.0
            for i in range(outer_i, outer_i + block):
                for j in range(outer_j, outer_j + block):
                    subtotal = _f32(subtotal + c[i * size + j])
            total = _f32(total + subtotal)

    # Every matrix entry and the final binary32 sum are integral in this
    # bounded domain; convert only after reproducing binary32 accumulation.
    return int(total)


def expected_output(
    values: Sequence[int],
    output_capacity: int = MAX_OUTPUT_BYTES,
    output_is_null: bool = False,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> tuple[int, bytes]:
    """Return the bounded profile's `final sum = %f\n` bytes or ABI error."""
    if (
        not isinstance(values, (tuple, list))
        or len(values) > MAX_INPUT_LENGTH
        or any(type(value) is not int or not -(2**63) <= value < 2**63 for value in values)
        or type(input_is_null) is not bool
        or type(output_is_null) is not bool
        or (input_is_null and (values or input_length not in (0, 2)))
        or (not input_is_null and input_length is not None
            and (type(input_length) is not int or input_length != len(values)))
    ):
        return INVALID_RESULT, b""
    if len(values) != 2:
        return INVALID_RESULT, b""
    if (type(output_capacity) is not int or output_capacity < 0
            or not 1 <= values[0] <= MAX_SIZE
            or not 1 <= values[1] <= values[0]
            or values[0] % values[1] != 0):
        return INVALID_RESULT, b""
    if output_is_null or output_capacity == 0:
        return OUTPUT_ERROR, b""

    total = _source_sum(values[0], values[1])
    output = f"final sum = {total}.000000\n".encode("ascii")
    if output_capacity < len(output):
        return OUTPUT_ERROR, b""
    return len(output), output
