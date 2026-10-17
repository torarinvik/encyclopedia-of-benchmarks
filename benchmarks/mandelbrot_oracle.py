"""Oracle for the bounded black-and-white Mandelbrot rendering contract."""

from __future__ import annotations

from collections.abc import Sequence

MAX_VALID_INPUT_VALUES = 6
MAX_PARSEABLE_INPUT_VALUES = 7
MAX_INPUT_VALUES = MAX_PARSEABLE_INPUT_VALUES
MIN_DIMENSION = 1
MAX_DIMENSION = 16
MIN_CENTER_Q = -64
MAX_CENTER_Q = 64
MIN_FIGURE_WIDTH_Q = 1
MAX_FIGURE_WIDTH_Q = 64
MIN_MAX_STEP = 2
MAX_MAX_STEP = 64
COORDINATE_SCALE = 16
MAX_OUTPUT_BYTES = MAX_DIMENSION * MAX_DIMENSION
BLACK = 0
WHITE = 255
INVALID_RESULT = -1
INSUFFICIENT_CAPACITY_RESULT = -2
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1


def _valid_input(values: Sequence[int] | None) -> tuple[int, int, float, float, float, int] | None:
    if (
        not isinstance(values, (list, tuple))
        or len(values) != MAX_VALID_INPUT_VALUES
        or any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values)
    ):
        return None
    width, height, center_x_q, center_y_q, figure_width_q, max_step = values
    if not MIN_DIMENSION <= width <= MAX_DIMENSION:
        return None
    if not MIN_DIMENSION <= height <= MAX_DIMENSION:
        return None
    if not MIN_CENTER_Q <= center_x_q <= MAX_CENTER_Q:
        return None
    if not MIN_CENTER_Q <= center_y_q <= MAX_CENTER_Q:
        return None
    if not MIN_FIGURE_WIDTH_Q <= figure_width_q <= MAX_FIGURE_WIDTH_Q:
        return None
    if not MIN_MAX_STEP <= max_step <= MAX_MAX_STEP:
        return None
    center_x = center_x_q / COORDINATE_SCALE
    center_y = center_y_q / COORDINATE_SCALE
    figure_width = figure_width_q / COORDINATE_SCALE
    return width, height, center_x, center_y, figure_width, max_step


def _render_pixels(values: Sequence[int] | None) -> bytes | None:
    decoded = _valid_input(values)
    if decoded is None:
        return None
    width, height, center_x, center_y, figure_width, max_step = decoded
    figure_height = figure_width / width * height
    output = bytearray()

    # Preserve the source loop order: x is the outer pixel coordinate.
    for image_x in range(width):
        figure_x = center_x + (image_x / width - 0.5) * figure_width
        for image_y in range(height):
            figure_y = center_y + (image_y / height - 0.5) * figure_height
            a = figure_x
            b = figure_y
            current_step = 0
            for step in range(max_step):
                current_step = step
                a_new = a * a - b * b + figure_x
                b = 2 * a * b + figure_y
                a = a_new
                if a * a + b * b > 4.0:
                    break
            distance = current_step / (max_step - 1)
            output.append(BLACK if distance >= 1.0 else WHITE)
    return bytes(output)


def expected_output(
    values: Sequence[int] | None,
    capacity: int | None = None,
    input_is_null: bool = False,
    output_is_null: bool = False,
    input_length: int | None = None,
) -> tuple[int, bytes]:
    """Return status and one black/white byte for each source-ordered pixel."""
    if input_is_null:
        return INVALID_RESULT, b""
    if input_length is not None and (
        type(input_length) is not int
        or not isinstance(values, (list, tuple))
        or input_length != len(values)
    ):
        return INVALID_RESULT, b""
    output = _render_pixels(values)
    if output is None:
        return INVALID_RESULT, b""
    if output_is_null or (capacity is not None and capacity < len(output)):
        return INSUFFICIENT_CAPACITY_RESULT, b""
    return len(output), output


def expected_result(
    values: Sequence[int] | None,
    capacity: int | None = None,
    input_is_null: bool = False,
    output_is_null: bool = False,
    input_length: int | None = None,
) -> int:
    """Return the ABI status/result code for an input view."""
    return expected_output(
        values, capacity, input_is_null, output_is_null, input_length
    )[0]

