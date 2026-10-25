"""Independent oracle for TSVC s343's masked column-major compaction core."""

from __future__ import annotations

import struct

MAX_ROWS = 8
MAX_COLS = 8
MAX_CELLS = MAX_ROWS * MAX_COLS
MAX_INPUT_LENGTH = 2 + 2 * MAX_CELLS
MAX_OUTPUT_BYTES = 8 * MAX_CELLS
I64_MIN = -(2**63)
I64_MAX = 2**63 - 1


def expected_output(
    values: tuple[int, ...] | list[int],
    output_capacity: int | None = None,
    output_is_null: bool = False,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> tuple[int, bytes]:
    if (
        not isinstance(values, (tuple, list))
        or type(output_is_null) is not bool
        or type(input_is_null) is not bool
        or output_capacity is not None
        and (type(output_capacity) is not int or output_capacity < 0)
        or input_length is not None
        and (type(input_length) is not int or input_length < 0 or input_length > MAX_INPUT_LENGTH)
        or any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values)
    ):
        return -1, b""

    if input_is_null:
        return -1, b""
    if len(values) < 4 or len(values) > MAX_INPUT_LENGTH:
        return -1, b""
    if input_length is not None and input_length != len(values):
        return -1, b""

    rows, cols = values[0], values[1]
    if not 1 <= rows <= MAX_ROWS or not 1 <= cols <= MAX_COLS:
        return -1, b""
    cells = rows * cols
    if len(values) != 2 + 2 * cells:
        return -1, b""
    required_capacity = cells * 8
    if output_is_null or (output_capacity is not None and output_capacity < required_capacity):
        return -2, b""

    data_start = 2
    mask_start = data_start + cells
    selected = []
    for col in range(cols):
        for row in range(rows):
            index = row * cols + col
            if values[mask_start + index] > 0:
                selected.append(values[data_start + index])
    output = b"".join(struct.pack("<q", value) for value in selected)
    return len(selected), output
