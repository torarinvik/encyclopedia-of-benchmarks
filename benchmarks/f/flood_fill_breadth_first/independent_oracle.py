"""Repeated full-grid closure reference for the bounded image component."""

from __future__ import annotations

import struct

SIDE_LIMIT = 32
CELL_LIMIT = SIDE_LIMIT * SIDE_LIMIT
VALID_WORD_LIMIT = 6 + CELL_LIMIT
PARSE_WORD_LIMIT = VALID_WORD_LIMIT + 1
OUTPUT_LIMIT = CELL_LIMIT * 8
SCRATCH_LIMIT = 16_384


def _parse_frame(words, declared_length):
    if type(declared_length) is not int or declared_length != len(words):
        return None
    if declared_length < 6 or declared_length > PARSE_WORD_LIMIT:
        return None
    if any(type(word) is not int or not -(1 << 63) <= word < (1 << 63) for word in words):
        return None
    columns, rows, seed_column, seed_row, replacement, source = words[:6]
    if columns < 1 or columns > SIDE_LIMIT or rows < 1 or rows > SIDE_LIMIT:
        return None
    if replacement < -(1 << 31) or replacement >= (1 << 31):
        return None
    if source < -(1 << 31) or source >= (1 << 31) or source == replacement:
        return None
    if declared_length != 6 + columns * rows:
        return None
    if seed_column < 0 or seed_column >= columns or seed_row < 0 or seed_row >= rows:
        return None
    image = words[6:]
    if any(pixel < -(1 << 31) or pixel >= (1 << 31) for pixel in image):
        return None
    return columns, rows, seed_column, seed_row, replacement, source, image


def _component_result(columns, rows, seed_column, seed_row, replacement, source, image):
    marked = [False] * (columns * rows)
    seed = seed_column * rows + seed_row
    if image[seed] == source:
        marked[seed] = True
        changed = True
        while changed:
            changed = False
            for x in range(columns):
                for y in range(rows):
                    index = x * rows + y
                    if marked[index] or image[index] != source:
                        continue
                    linked = False
                    for nx in range(max(0, x - 1), min(columns, x + 2)):
                        for ny in range(max(0, y - 1), min(rows, y + 2)):
                            if marked[nx * rows + ny]:
                                linked = True
                    if linked:
                        marked[index] = True
                        changed = True
    return [replacement if marked[index] else image[index] for index in range(len(image))]


def expected_output(input_values, output_capacity=None, output_is_null=False,
                    input_is_null=False, input_length=None):
    if type(input_is_null) is not bool or input_is_null or not isinstance(input_values, (list, tuple)):
        return -1, b""
    words = list(input_values)
    declared_length = len(words) if input_length is None else input_length
    frame = _parse_frame(words, declared_length)
    if frame is None:
        return -1, b""
    columns, rows, sx, sy, replacement, source, image = frame
    result = _component_result(columns, rows, sx, sy, replacement, source, image)
    payload = b"".join(struct.pack("<q", pixel) for pixel in result)
    if type(output_is_null) is not bool or output_is_null:
        return -2, b""
    if output_capacity is not None and (type(output_capacity) is not int or output_capacity < len(payload)):
        return -2, b""
    return len(payload), payload
