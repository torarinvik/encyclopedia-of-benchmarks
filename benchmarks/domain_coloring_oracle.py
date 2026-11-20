"""Primary reference for the integer domain-coloring benchmark."""

from __future__ import annotations

from collections.abc import Sequence

MAX_VALID_INPUT_LENGTH = 6
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_OUTPUT_BYTES = 16 * 16 * 3
WORKSPACE_BYTES = MAX_OUTPUT_BYTES
INVALID_RESULT = -1
OUTPUT_ERROR = -2
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1


def _phase_hue(real_part: int, imaginary_part: int) -> int:
    if real_part == 0 and imaginary_part == 0:
        return 0
    abs_real = abs(real_part)
    abs_imaginary = abs(imaginary_part)
    high = max(abs_real, abs_imaginary)
    low = min(abs_real, abs_imaginary)
    step = 192 * low // high

    if imaginary_part >= 0:
        if real_part >= 0:
            hue = step if abs_real >= abs_imaginary else 384 - step
        else:
            hue = 384 + step if abs_real < abs_imaginary else 768 - step
    elif real_part < 0:
        hue = 768 + step if abs_real >= abs_imaginary else 1152 - step
    else:
        hue = 1152 + step if abs_real < abs_imaginary else 1536 - step
    return hue % 1536


def _rgb(hue: int, magnitude_16: int) -> tuple[int, int, int]:
    value = 128 + 8 * (magnitude_16 % 16)
    sector, fraction = divmod(hue, 256)
    rising = value * fraction // 255
    falling = value * (255 - fraction) // 255
    if sector == 0:
        return value, rising, 0
    if sector == 1:
        return falling, value, 0
    if sector == 2:
        return 0, value, rising
    if sector == 3:
        return 0, falling, value
    if sector == 4:
        return rising, 0, value
    return value, 0, falling


def _render(values: Sequence[int] | None) -> bytes | None:
    if (
        not isinstance(values, (tuple, list))
        or len(values) != 6
        or any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values)
    ):
        return None
    width, height, x_start, y_start, x_step, y_step = values
    if not 1 <= width <= 16 or not 1 <= height <= 16:
        return None
    if not -32 <= x_start <= 32 or not -32 <= y_start <= 32:
        return None
    if not -8 <= x_step <= 8 or not -8 <= y_step <= 8:
        return None
    x_end = x_start + (width - 1) * x_step
    y_end = y_start + (height - 1) * y_step
    if not -32 <= x_end <= 32 or not -32 <= y_end <= 32:
        return None

    pixels = bytearray()
    for row in range(height):
        y_q = y_start + row * y_step
        for column in range(width):
            x_q = x_start + column * x_step
            # These are the exact integer numerators for (x_q+i*y_q)^2 / 16.
            real_part = x_q * x_q - y_q * y_q
            imaginary_part = 2 * x_q * y_q
            magnitude_16 = x_q * x_q + y_q * y_q
            pixels.extend(_rgb(_phase_hue(real_part, imaginary_part), magnitude_16))
    return bytes(pixels)


def expected_output(
    values: Sequence[int] | None,
    capacity: int | None = None,
    input_is_null: bool = False,
    output_is_null: bool = False,
    input_length: int | None = None,
) -> tuple[int, bytes]:
    if input_is_null:
        return INVALID_RESULT, b""
    if input_length is not None and (
        type(input_length) is not int
        or not isinstance(values, (tuple, list))
        or input_length != len(values)
    ):
        return INVALID_RESULT, b""
    rendered = _render(values)
    if rendered is None:
        return INVALID_RESULT, b""
    if output_is_null or (capacity is not None and capacity < len(rendered)):
        return OUTPUT_ERROR, b""
    return len(rendered), rendered


def expected_result(
    values: Sequence[int] | None,
    capacity: int | None = None,
    input_is_null: bool = False,
    output_is_null: bool = False,
    input_length: int | None = None,
) -> int:
    return expected_output(values, capacity, input_is_null, output_is_null, input_length)[0]
