"""Fixed-point oracle for the bounded grayscale Canny benchmark."""

from __future__ import annotations

MAX_SIDE = 16
MAX_PIXELS = MAX_SIDE * MAX_SIDE
_NORM = 1 << 20
_ANGLE_SCALE = 1_000_000_000
_TAN_22_5_Q9 = 414_213_562
_GAUSSIAN_Q20 = (
    (85_321, 66_110, 30_754, 8_589, 1_440),
    (66_110, 51_225, 23_829, 6_655, 1_116),
    (30_754, 23_829, 11_085, 3_096, 519),
    (8_589, 6_655, 3_096, 865, 145),
    (1_440, 1_116, 519, 145, 24),
)
_SOBEL_X = ((-1, 0, 1), (-2, 0, 2), (-1, 0, 1))
_SOBEL_Y = ((1, 2, 1), (0, 0, 0), (-1, -2, -1))


def _isqrt(value: int) -> int:
    """Floor square root without floating-point or machine-specific operations."""
    if value < 2:
        return value
    low, high = 1, min(value, 1 << 32)
    while low <= high:
        middle = (low + high) // 2
        if middle <= value // middle:
            low = middle + 1
        else:
            high = middle - 1
    return high


def _canny(values: list[int]) -> tuple[int, bytes]:
    if not values or type(values[0]) is not int:
        return -1, b""
    side = values[0]
    if not 1 <= side <= MAX_SIDE or len(values) != 1 + side * side:
        return -1, b""
    pixels = values[1:]
    if any(type(value) is not int or not 0 <= value <= 255 for value in pixels):
        return -1, b""

    blurred = [0] * (side * side)
    for row in range(side):
        for column in range(side):
            total = 0
            for kernel_y in range(-4, 5):
                source_row = min(side - 1, max(0, row + kernel_y))
                for kernel_x in range(-4, 5):
                    source_column = min(side - 1, max(0, column + kernel_x))
                    weight = _GAUSSIAN_Q20[abs(kernel_y)][abs(kernel_x)]
                    total += weight * pixels[source_row * side + source_column]
            blurred[row * side + column] = total

    gradient_x = [0] * (side * side)
    gradient_y = [0] * (side * side)
    maximum_x = maximum_y = 0
    for row in range(side):
        for column in range(side):
            total_x = total_y = 0
            for kernel_y in range(-1, 2):
                source_row = min(side - 1, max(0, row + kernel_y))
                for kernel_x in range(-1, 2):
                    source_column = min(side - 1, max(0, column + kernel_x))
                    sample = blurred[source_row * side + source_column]
                    total_x += sample * _SOBEL_X[kernel_y + 1][kernel_x + 1]
                    total_y += sample * _SOBEL_Y[kernel_y + 1][kernel_x + 1]
            total_x, total_y = abs(total_x), abs(total_y)
            offset = row * side + column
            gradient_x[offset] = total_x
            gradient_y[offset] = total_y
            maximum_x = max(maximum_x, total_x)
            maximum_y = max(maximum_y, total_y)

    normalized_x = [value * 255 * _NORM // maximum_x if maximum_x else 0
                    for value in gradient_x]
    normalized_y = [value * 255 * _NORM // maximum_y if maximum_y else 0
                    for value in gradient_y]
    magnitudes = [_isqrt(x_value * x_value + y_value * y_value)
                  for x_value, y_value in zip(normalized_x, normalized_y)]
    maximum_magnitude = max(magnitudes, default=0)
    if maximum_magnitude:
        magnitudes = [value * 255 // maximum_magnitude for value in magnitudes]
    else:
        magnitudes = [0] * (side * side)

    suppressed = [0] * (side * side)
    for row in range(1, side - 1):
        for column in range(1, side - 1):
            offset = row * side + column
            horizontal_value = normalized_x[offset]
            vertical_value = normalized_y[offset]
            if vertical_value * _ANGLE_SCALE < horizontal_value * _TAN_22_5_Q9:
                before = magnitudes[offset - 1]
                after = magnitudes[offset + 1]
            elif horizontal_value * _ANGLE_SCALE <= vertical_value * _TAN_22_5_Q9:
                before = magnitudes[offset - side]
                after = magnitudes[offset + side]
            else:
                before = magnitudes[offset + side - 1]
                after = magnitudes[offset - side + 1]
            magnitude = magnitudes[offset]
            if magnitude >= before and magnitude >= after:
                suppressed[offset] = magnitude

    for offset in range(len(suppressed)):
        magnitude = suppressed[offset]
        if magnitude >= 30:
            suppressed[offset] = 255
        elif magnitude <= 15:
            suppressed[offset] = 0
        else:
            suppressed[offset] = 128

    # Match the source's row-major, one-pass hysteresis; limit it to interior
    # pixels so each eight-neighbor lookup stays inside the image.
    for row in range(1, side - 1):
        for column in range(1, side - 1):
            offset = row * side + column
            if suppressed[offset] == 128:
                connected = any(
                    suppressed[(row + delta_y) * side + column + delta_x] == 255
                    for delta_y in (-1, 0, 1)
                    for delta_x in (-1, 0, 1)
                    if delta_x or delta_y
                )
                suppressed[offset] = 255 if connected else 0

    return len(suppressed), bytes(suppressed)


def expected_output(values: list[int]) -> tuple[int, bytes]:
    if (not isinstance(values, list) or len(values) > 1 + MAX_PIXELS
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return -1, b""
    return _canny(values)


def encode_output(values: list[int]) -> str:
    """Small diagnostic helper used when creating checked workload fixtures."""
    result, output = expected_output(values)
    return f"{result}:{output.hex()}"
