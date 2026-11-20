"""LIFO-stack reference for bounded eight-connected flood fill."""

from __future__ import annotations

import struct

MAX_SIDE = 32
MAX_CELLS = MAX_SIDE * MAX_SIDE
MAX_VALID_INPUT_LENGTH = 6 + MAX_CELLS
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_OUTPUT_BYTES = 8 * MAX_CELLS
WORKSPACE_BYTES = 16_384


def _decode(values: list[int], length: int):
    if length != len(values) or not 6 <= length <= MAX_PARSEABLE_INPUT_LENGTH:
        return None
    if any(type(value) is not int or not -(1 << 63) <= value < (1 << 63) for value in values):
        return None
    width, height, start_x, start_y, new_color, target_color = values[:6]
    if not 1 <= width <= MAX_SIDE or not 1 <= height <= MAX_SIDE:
        return None
    if not -(1 << 31) <= new_color < (1 << 31) or not -(1 << 31) <= target_color < (1 << 31):
        return None
    if new_color == target_color or length != 6 + width * height:
        return None
    if not 0 <= start_x < width or not 0 <= start_y < height:
        return None
    pixels = values[6:]
    if any(not -(1 << 31) <= color < (1 << 31) for color in pixels):
        return None
    return width, height, start_x, start_y, new_color, target_color, pixels


def _fill(width: int, height: int, start_x: int, start_y: int,
          new_color: int, target_color: int, pixels: list[int]) -> list[int]:
    image = pixels.copy()
    start = start_x * height + start_y
    if image[start] != target_color:
        return image
    stack = [start]
    image[start] = new_color
    while stack:
        index = stack.pop()
        x, y = divmod(index, height)
        for dx in (-1, 0, 1):
            for dy in (-1, 0, 1):
                if dx == 0 and dy == 0:
                    continue
                nx, ny = x + dx, y + dy
                if 0 <= nx < width and 0 <= ny < height:
                    neighbor = nx * height + ny
                    if image[neighbor] == target_color:
                        image[neighbor] = new_color
                        stack.append(neighbor)
    return image


def expected_output(
    input_values: list[int], output_capacity: int | None = None,
    output_is_null: bool = False, input_is_null: bool = False,
    input_length: int | None = None,
) -> tuple[int, bytes]:
    if type(input_is_null) is not bool or input_is_null or not isinstance(input_values, (list, tuple)):
        return -1, b""
    length = len(input_values) if input_length is None else input_length
    if type(length) is not int:
        return -1, b""
    decoded = _decode(list(input_values), length)
    if decoded is None:
        return -1, b""
    width, height, sx, sy, fresh, target, pixels = decoded
    result = _fill(width, height, sx, sy, fresh, target, pixels)
    payload = b"".join(struct.pack("<q", value) for value in result)
    if type(output_is_null) is not bool or output_is_null:
        return -2, b""
    if output_capacity is not None and (type(output_capacity) is not int or output_capacity < len(payload)):
        return -2, b""
    return len(payload), payload
