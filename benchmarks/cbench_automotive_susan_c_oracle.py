"""Independent bounded oracle for cBench SUSAN corner detection.

/**********************************************************************\
  SUSAN Version 2l by Stephen Smith
  Oxford Centre for Functional Magnetic Resonance Imaging of the Brain,
  Department of Clinical Neurology, Oxford University, Oxford, UK
  (Previously in Computer Vision and Image Processing Group - now
  Computer Vision and Electro Optics Group - DERA Chertsey, UK)
  Email:    steve@fmrib.ox.ac.uk
  WWW:      http://www.fmrib.ox.ac.uk/~steve
  (C) Crown Copyright (1995-1999), Defence Evaluation and Research Agency,
  Farnborough, Hampshire, GU14 6TD, UK
  DERA WWW site:
  http://www.dera.gov.uk/
  DERA Computer Vision and Electro Optics Group WWW site:
  http://www.dera.gov.uk/imageprocessing/dera/group_home.html
  DERA Computer Vision and Electro Optics Group point of contact:
  Dr. John Savage, jtsavage@dera.gov.uk, +44 1344 633203
  A UK patent has been granted: "Method for digitally processing
  images to determine the position of edges and/or corners therein for
  guidance of unmanned vehicle", UK Patent 2272285. Proprietor:
  Secretary of State for Defence, UK. 15 January 1997

  This code is issued for research purposes only and remains the
  property of the UK Secretary of State for Defence. This code must
  not be passed on without this header information being kept
  intact. This code must not be sold.
\**********************************************************************/
"""

from __future__ import annotations

import math
import struct
from typing import Sequence

MIN_SIDE = 11
MAX_SIDE = 16
MAX_VALID_INPUT_LENGTH = 257
MAX_PARSEABLE_INPUT_LENGTH = 258
MAX_OUTPUT_BYTES = 256
MAX_CORNERS = 1850
BRIGHTNESS_THRESHOLD = 20

_MASK = tuple(
    (dx, dy)
    for dy in range(-3, 4)
    for dx in range(-3, 4)
    if (dx, dy) != (0, 0)
    and (abs(dy) < 3 or abs(dx) <= 1)
    and (abs(dy) != 2 or abs(dx) <= 2)
    and (dy != 0 or abs(dx) >= 1)
)


def _f32(value: float) -> float:
    return struct.unpack("=f", struct.pack("=f", value))[0]


def _trunc_div(numerator: int, denominator: int) -> int:
    quotient = abs(numerator) // abs(denominator)
    return -quotient if (numerator < 0) != (denominator < 0) else quotient


def _ftoi(value: float) -> int:
    value = _f32(value)
    return math.floor(value + 0.5) if value >= 0.0 else math.ceil(value - 0.5)


def _brightness_table() -> list[int]:
    table = [0] * 513
    for difference in range(-256, 257):
        scaled = abs(difference) / BRIGHTNESS_THRESHOLD
        term = scaled * scaled
        term = term * term * term
        table[difference + 256] = int(100.0 * math.exp(-term))
    return table


_BRIGHTNESS = _brightness_table()


def _is_local_corner(response: Sequence[int], side: int, y: int, x: int) -> bool:
    value = response[y * side + x]
    for dy in range(-3, 4):
        for dx in range(-3, 4):
            if dx == 0 and dy == 0:
                continue
            other = response[(y + dy) * side + x + dx]
            if dy < 0 or (dy == 0 and dx < 0):
                if value <= other:
                    return False
            elif value < other:
                return False
    return True


def _draw_corners(image: list[int], side: int, points: Sequence[tuple[int, int]]) -> None:
    for x, y in points:
        top = (y - 1) * side + x - 1
        image[top] = 255
        image[top + 1] = 255
        image[top + 2] = 255
        image[top + side] = 255
        image[top + side + 1] = 0
        image[top + side + 2] = 255
        image[top + 2 * side] = 255
        image[top + 2 * side + 1] = 255
        image[top + 2 * side + 2] = 255


def _susan_corners(image: list[int], side: int) -> None:
    response = [0] * (side * side)
    gradients_x = [0] * (side * side)
    gradients_y = [0] * (side * side)

    for y in range(5, side - 5):
        for x in range(5, side - 5):
            center = image[y * side + x]
            area = 100 + sum(
                _BRIGHTNESS[center - image[(y + dy) * side + x + dx] + 256]
                for dx, dy in _MASK
            )
            if area >= MAX_CORNERS:
                continue

            gx = 0
            gy = 0
            for dx, dy in _MASK:
                contribution = _BRIGHTNESS[
                    center - image[(y + dy) * side + x + dx] + 256
                ]
                gx += dx * contribution
                gy += dy * contribution

            xx = gx * gx
            yy = gy * gy
            if xx + yy <= (area * area) // 2:
                continue

            if yy < xx:
                slope = _f32(_f32(float(gy)) / _f32(float(abs(gx))))
                step_x = _trunc_div(abs(gx), gx)
                along = sum(
                    _BRIGHTNESS[
                        center
                        - image[(y + _ftoi(distance * slope)) * side + x + distance * step_x]
                        + 256
                    ]
                    for distance in (1, 2, 3)
                )
            else:
                slope = _f32(_f32(float(gx)) / _f32(float(abs(gy))))
                step_y = _trunc_div(abs(gy), gy)
                along = sum(
                    _BRIGHTNESS[
                        center
                        - image[(y + distance * step_y) * side + x + _ftoi(distance * slope)]
                        + 256
                    ]
                    for distance in (1, 2, 3)
                )

            if along > 290:
                index = y * side + x
                response[index] = MAX_CORNERS - area
                gradients_x[index] = _trunc_div(51 * gx, area)
                gradients_y[index] = _trunc_div(51 * gy, area)

    points: list[tuple[int, int]] = []
    for y in range(5, side - 5):
        for x in range(5, side - 5):
            if response[y * side + x] > 0 and _is_local_corner(response, side, y, x):
                points.append((x, y))
    _draw_corners(image, side, points)


def expected_output(
    values: Sequence[int],
    output_capacity: int | None = None,
    output_is_null: bool = False,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> tuple[int, bytes]:
    if input_is_null or not isinstance(values, (tuple, list)):
        return -1, b""
    if input_length is None:
        input_length = len(values)
    if (
        input_length < 2
        or input_length > MAX_PARSEABLE_INPUT_LENGTH
        or input_length != len(values)
    ):
        return -1, b""
    if any(not isinstance(value, int) or value < -(1 << 63) or value >= (1 << 63) for value in values):
        return -1, b""
    side = values[0]
    if side < MIN_SIDE or side > MAX_SIDE or input_length != side * side + 1:
        return -1, b""
    pixels = values[1:]
    if any(pixel < 0 or pixel > 255 for pixel in pixels):
        return -1, b""
    if output_is_null:
        return -2, b""
    if output_capacity is None:
        output_capacity = MAX_OUTPUT_BYTES
    if output_capacity < side * side:
        return -2, b""

    image = list(pixels)
    _susan_corners(image, side)
    return side * side, bytes(image)
