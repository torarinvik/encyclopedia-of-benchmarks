"""Oracle for the bounded, packed-output port of the pinned Java WusLine."""

from __future__ import annotations

import math
import struct

COORDINATE_LIMIT = 64
MAX_PIXEL_COUNT = 258
MAX_OUTPUT_BYTES = MAX_PIXEL_COUNT * 16
MAX_INPUT_LENGTH = 4


def _fraction_part(value: float) -> float:
    return value - math.floor(value)


def _reverse_fraction_part(value: float) -> float:
    return 1.0 - _fraction_part(value)


def _append_pixel(pixels: list[tuple[int, int, float]], x: int, y: int,
                  intensity: float, steep: bool) -> None:
    x_coordinate, y_coordinate = (y, x) if steep else (x, y)
    pixels.append((x_coordinate, y_coordinate, min(1.0, max(0.0, intensity))))


def expected_output(values: list[int] | tuple[int, ...]) -> tuple[int, bytes]:
    """Return (byte count, bytes) using Java WusLine's emission order."""
    if (not isinstance(values, (list, tuple)) or len(values) != 4
            or any(type(value) is not int or not -(2**63) <= value < 2**63
                   for value in values)):
        return -1, b""
    if any(value < -COORDINATE_LIMIT or value > COORDINATE_LIMIT for value in values):
        return -1, b""

    x0, y0, x1, y1 = values
    steep = abs(y1 - y0) > abs(x1 - x0)
    if steep:
        x0, y0 = y0, x0
        x1, y1 = y1, x1
    if x0 > x1:
        x0, x1 = x1, x0
        y0, y1 = y1, y0

    delta_x = float(x1) - float(x0)
    delta_y = float(y1) - float(y0)
    gradient = 1.0 if delta_x == 0.0 else delta_y / delta_x

    def endpoint(x: int, y: int, is_start: bool) -> tuple[int, int, float, float]:
        x_end = math.floor(float(x) + 0.5)
        y_end = float(y) + gradient * (float(x_end) - float(x))
        x_gap = (_reverse_fraction_part(float(x) + 0.5) if is_start
                 else _fraction_part(float(x) + 0.5))
        return x_end, math.floor(y_end), y_end, x_gap

    first = endpoint(x0, y0, True)
    second = endpoint(x1, y1, False)
    pixels: list[tuple[int, int, float]] = []

    def add_endpoint(data: tuple[int, int, float, float]) -> None:
        x_pixel, y_pixel, y_end, x_gap = data
        fractional_y = _fraction_part(y_end)
        complement_fractional_y = _reverse_fraction_part(y_end)
        _append_pixel(pixels, x_pixel, y_pixel,
                      complement_fractional_y * x_gap, steep)
        _append_pixel(pixels, x_pixel, y_pixel + 1,
                      fractional_y * x_gap, steep)

    add_endpoint(first)
    add_endpoint(second)

    intersection_y = first[2] + gradient
    for x_pixel in range(first[0] + 1, second[0]):
        y_floor = math.floor(intersection_y)
        fractional_part = _fraction_part(intersection_y)
        complement_fractional_part = _reverse_fraction_part(intersection_y)
        _append_pixel(pixels, x_pixel, y_floor, complement_fractional_part, steep)
        _append_pixel(pixels, x_pixel, y_floor + 1, fractional_part, steep)
        intersection_y += gradient

    output = b"".join(struct.pack("<iid", x, y, intensity)
                      for x, y, intensity in pixels)
    return len(output), output
