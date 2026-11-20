"""Grid-wide fixed-point reference for bounded eight-connected flood fill."""

from __future__ import annotations

import struct

MAX_SIDE = 32
MAX_CELLS = MAX_SIDE * MAX_SIDE
MAX_VALID_INPUT_LENGTH = 6 + MAX_CELLS
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_OUTPUT_BYTES = 8 * MAX_CELLS
WORKSPACE_BYTES = 16_384


def _parse(values, declared_length):
    if type(declared_length) is not int or declared_length != len(values):
        return None
    if declared_length < 6 or declared_length > MAX_PARSEABLE_INPUT_LENGTH:
        return None
    if any(type(word) is not int or not -(1 << 63) <= word < (1 << 63) for word in values):
        return None
    width, height, sx, sy, replacement, source = values[:6]
    if not 1 <= width <= MAX_SIDE or not 1 <= height <= MAX_SIDE:
        return None
    if not -(1 << 31) <= replacement < (1 << 31):
        return None
    if not -(1 << 31) <= source < (1 << 31) or source == replacement:
        return None
    if declared_length != 6 + width * height:
        return None
    if not 0 <= sx < width or not 0 <= sy < height:
        return None
    pixels = values[6:]
    if any(not -(1 << 31) <= pixel < (1 << 31) for pixel in pixels):
        return None
    return width, height, sx, sy, replacement, source, pixels


def _replace_component(width, height, sx, sy, replacement, source, pixels):
    marked = [False] * len(pixels)
    seed = sx * height + sy
    if pixels[seed] == source:
        marked[seed] = True
        changed = True
        while changed:
            changed = False
            for x in range(width):
                for y in range(height):
                    index = x * height + y
                    if marked[index] or pixels[index] != source:
                        continue
                    for nx in range(max(0, x - 1), min(width, x + 2)):
                        for ny in range(max(0, y - 1), min(height, y + 2)):
                            if marked[nx * height + ny]:
                                marked[index] = True
                                changed = True
                                break
                        if marked[index]:
                            break
    return [replacement if marked[i] else pixels[i] for i in range(len(pixels))]


def expected_output(values, output_capacity=None, output_is_null=False,
                    input_is_null=False, input_length=None):
    if type(input_is_null) is not bool or input_is_null or not isinstance(values, (list, tuple)):
        return -1, b""
    words = list(values)
    declared_length = len(words) if input_length is None else input_length
    parsed = _parse(words, declared_length)
    if parsed is None:
        return -1, b""
    width, height, sx, sy, replacement, source, pixels = parsed
    result = _replace_component(width, height, sx, sy, replacement, source, pixels)
    payload = b"".join(struct.pack("<q", pixel) for pixel in result)
    if type(output_is_null) is not bool or output_is_null:
        return -2, b""
    if output_capacity is not None and (type(output_capacity) is not int or output_capacity < len(payload)):
        return -2, b""
    return len(payload), payload
