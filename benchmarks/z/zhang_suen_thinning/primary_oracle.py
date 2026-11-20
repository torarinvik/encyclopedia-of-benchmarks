"""Primary clean-room implementation of Zhang-Suen binary thinning."""

from __future__ import annotations

from collections.abc import Sequence

MAX_ROWS = 32
MAX_COLUMNS = 32
MAX_CELLS = MAX_ROWS * MAX_COLUMNS
MAX_VALID_INPUT_LENGTH = 2 + MAX_CELLS
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_OUTPUT_BYTES = MAX_CELLS
WORKSPACE_BYTES = 2 * MAX_CELLS
INVALID_RESULT = -1
OUTPUT_ERROR_RESULT = -2


def _parse(values: Sequence[int] | None, input_is_null: bool,
           input_length: int | None):
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple))
            or not 2 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
            or any(type(word) is not int or not -(1 << 63) <= word < (1 << 63)
                   for word in values)):
        return None
    if input_length is not None and (
            type(input_length) is not int or input_length != len(values)):
        return None
    rows, columns = values[:2]
    if not 1 <= rows <= MAX_ROWS or not 1 <= columns <= MAX_COLUMNS:
        return None
    cells = rows * columns
    if len(values) != 2 + cells:
        return None
    image = bytearray(values[2:])
    if any(pixel not in (0, 1) for pixel in image):
        return None
    return rows, columns, image


def _thin_pass(image: bytearray, rows: int, columns: int,
               second: bool) -> bool:
    marked = bytearray(rows * columns)
    changed = False
    for row in range(1, rows - 1):
        for column in range(1, columns - 1):
            index = row * columns + column
            if image[index] == 0:
                continue
            # P2..P9 are clockwise from north.
            p2 = image[index - columns]
            p3 = image[index - columns + 1]
            p4 = image[index + 1]
            p5 = image[index + columns + 1]
            p6 = image[index + columns]
            p7 = image[index + columns - 1]
            p8 = image[index - 1]
            p9 = image[index - columns - 1]
            neighbors = (p2, p3, p4, p5, p6, p7, p8, p9)
            count = sum(neighbors)
            if count < 2 or count > 6:
                continue
            ring = (*neighbors, p2)
            transitions = sum(
                ring[position] == 0 and ring[position + 1] == 1
                for position in range(8)
            )
            if transitions != 1:
                continue
            if second:
                keep_if_all_black = (p2, p4, p8, p2, p6, p8)
            else:
                keep_if_all_black = (p2, p4, p6, p4, p6, p8)
            if keep_if_all_black[0] and keep_if_all_black[1] and keep_if_all_black[2]:
                continue
            if keep_if_all_black[3] and keep_if_all_black[4] and keep_if_all_black[5]:
                continue
            marked[index] = 1
            changed = True
    if changed:
        for index, flag in enumerate(marked):
            if flag:
                image[index] = 0
    return changed


def expected_output(values: Sequence[int] | None, capacity: int = MAX_OUTPUT_BYTES,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    parsed = _parse(values, input_is_null, input_length)
    if parsed is None:
        return INVALID_RESULT, b""
    if type(capacity) is not int or capacity < 0 or type(output_is_null) is not bool:
        return OUTPUT_ERROR_RESULT, b""
    rows, columns, image = parsed
    cells = rows * columns
    if output_is_null or capacity < cells:
        return OUTPUT_ERROR_RESULT, b""

    while True:
        changed_first = _thin_pass(image, rows, columns, second=False)
        changed_second = _thin_pass(image, rows, columns, second=True)
        if not (changed_first or changed_second):
            break
    return cells, bytes(image)
