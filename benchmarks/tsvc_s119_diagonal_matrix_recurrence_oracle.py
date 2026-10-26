"""Independent oracle for the bounded TSVC s119 diagonal recurrence."""
from __future__ import annotations
import struct
from collections.abc import Sequence

MAX_SIDE = 8
MAX_PASSES = 4
MAX_CELLS = MAX_SIDE * MAX_SIDE
MAX_INPUT_LENGTH = 2 + 2 * MAX_CELLS
MAX_OUTPUT_BYTES = 8 * MAX_CELLS
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1


def expected_output(values: Sequence[int] | None, output_capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if (not isinstance(values, (list, tuple))
            or type(output_is_null) is not bool or type(input_is_null) is not bool
            or output_capacity is not None and (type(output_capacity) is not int or output_capacity < 0)
            or input_length is not None and (type(input_length) is not int or input_length < 0 or input_length > MAX_INPUT_LENGTH)
            or any(type(x) is not int or not I64_MIN <= x <= I64_MAX for x in values)):
        return -1, b""
    if input_is_null or not 10 <= len(values) <= MAX_INPUT_LENGTH:
        return -1, b""
    if input_length is not None and input_length != len(values):
        return -1, b""
    side, passes = values[:2]
    if not 2 <= side <= MAX_SIDE or not 1 <= passes <= MAX_PASSES:
        return -1, b""
    cells = side * side
    if len(values) != 2 + 2 * cells:
        return -1, b""
    a = [list(values[2 + row * side:2 + (row + 1) * side]) for row in range(side)]
    b = [list(values[2 + cells + row * side:2 + cells + (row + 1) * side]) for row in range(side)]
    if any(not -2 <= x <= 2 for row in a for x in row) or any(not -2 <= x <= 2 for row in b for x in row):
        return -1, b""
    if output_is_null or output_capacity is not None and output_capacity < 8 * cells:
        return -2, b""
    for _ in range(passes):
        for row in range(1, side):
            for col in range(1, side):
                a[row][col] = a[row - 1][col - 1] + b[row][col]
    flat = [x for row in a for x in row]
    return cells, b"".join(struct.pack("<q", x) for x in flat)
