"""Reference output for bounded image and normalized-box flipping."""

from __future__ import annotations

import struct

MAX_WIDTH = 16
MAX_HEIGHT = 16
MAX_BOXES = 16
COORDINATE_SCALE = 1_000_000
MAX_INPUT_LENGTH = 4 + MAX_WIDTH * MAX_HEIGHT + 5 * MAX_BOXES
MAX_OUTPUT_BYTES = MAX_WIDTH * MAX_HEIGHT + 20 * MAX_BOXES


def expected_output(values: list[int]) -> tuple[int, bytes]:
    if (not isinstance(values, list) or not 4 <= len(values) <= MAX_INPUT_LENGTH
            or any(type(value) is not int or not -(2**63) <= value < 2**63
                   for value in values)):
        return -1, b""
    width, height, flip_type, box_count = values[:4]
    if not 1 <= width <= MAX_WIDTH or not 1 <= height <= MAX_HEIGHT:
        return -1, b""
    if flip_type not in (0, 1) or not 0 <= box_count <= MAX_BOXES:
        return -1, b""
    pixel_count = width * height
    if len(values) != 4 + pixel_count + 5 * box_count:
        return -1, b""
    pixels = values[4:4 + pixel_count]
    if any(not 0 <= pixel <= 255 for pixel in pixels):
        return -1, b""
    boxes = values[4 + pixel_count:]
    for index in range(box_count):
        label, x_center, y_center, box_width, box_height = boxes[index * 5:index * 5 + 5]
        if (not 0 <= label <= 2**31 - 1
                or any(not 0 <= coordinate <= COORDINATE_SCALE
                       for coordinate in (x_center, y_center, box_width, box_height))):
            return -1, b""

    flipped = bytearray(pixel_count)
    for row in range(height):
        for column in range(width):
            source_row = height - 1 - row if flip_type == 0 else row
            source_column = width - 1 - column if flip_type == 1 else column
            flipped[row * width + column] = pixels[source_row * width + source_column]
    output = bytearray(flipped)
    for index in range(box_count):
        label, x_center, y_center, box_width, box_height = boxes[index * 5:index * 5 + 5]
        if flip_type == 1:
            x_center = COORDINATE_SCALE - x_center
        else:
            y_center = COORDINATE_SCALE - y_center
        output.extend(struct.pack("<5i", label, x_center, y_center, box_width, box_height))
    return len(output), bytes(output)
