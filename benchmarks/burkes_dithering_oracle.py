"""Exact integer contract for the bounded Burkes dithering benchmark."""

from __future__ import annotations

MAX_SIDE = 7
MAX_INPUT_LENGTH = 3 + 3 * MAX_SIDE * MAX_SIDE


def _truncate_division(value: int, divisor: int) -> int:
    magnitude = abs(value) // divisor
    return -magnitude if value < 0 else magnitude


def expected_result(values: list[int]) -> int:
    if (not isinstance(values, list) or len(values) < 3 or len(values) > MAX_INPUT_LENGTH
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return -1
    side, threshold = values[:2]
    if not 1 <= side <= MAX_SIDE or not 1 <= threshold <= 254:
        return -1
    if len(values) != 2 + 3 * side * side:
        return -1
    pixels = values[2:]
    if any(not 0 <= channel <= 255 for channel in pixels):
        return -1

    stride = side + 4
    errors = [0] * ((side + 1) * stride)
    white_pixels = 0
    for y in range(side):
        for x in range(side):
            offset = 2 + 3 * (y * side + x)
            blue, green, red = pixels[offset - 2:offset + 1]
            gray = (114 * blue + 587 * green + 299 * red) // 1000
            adjusted_gray = gray + errors[y * stride + x]
            if threshold > adjusted_gray:
                current_error = adjusted_gray
            else:
                white_pixels |= 1 << (y * side + x)
                current_error = adjusted_gray - 255

            errors[y * stride + x + 1] += _truncate_division(8 * current_error, 32)
            errors[y * stride + x + 2] += _truncate_division(4 * current_error, 32)
            errors[(y + 1) * stride + x] += _truncate_division(8 * current_error, 32)
            errors[(y + 1) * stride + x + 1] += _truncate_division(4 * current_error, 32)
            errors[(y + 1) * stride + x + 2] += _truncate_division(2 * current_error, 32)
            errors[(y + 1) * stride + x - 1] += _truncate_division(4 * current_error, 32)
            errors[(y + 1) * stride + x - 2] += _truncate_division(2 * current_error, 32)
    return white_pixels
