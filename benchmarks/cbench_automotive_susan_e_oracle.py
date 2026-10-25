"""Independent bounded oracle for cBench SUSAN edge detection.

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
MAX_PARSEABLE_INPUT_LENGTH = 258
MAX_OUTPUT_BYTES = 256
MAX_NO_EDGES = 2650
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


def _brightness_table() -> list[int]:
    table = [0] * 513
    for difference in range(-256, 257):
        scaled = abs(difference) / BRIGHTNESS_THRESHOLD
        term = scaled * scaled
        term = term * term * term
        table[difference + 256] = int(100.0 * math.exp(-term))
    return table


_BRIGHTNESS = _brightness_table()


def _edge_orientation(gx: int, gy: int) -> tuple[int, int, int]:
    if gx == 0:
        slope = _f32(1_000_000.0)
    else:
        slope = _f32(_f32(float(gy)) / _f32(float(gx)))
    sign = -1 if slope < 0.0 else 1
    slope = abs(slope)
    if slope < 0.5:
        return 0, 1, sign
    if slope > 2.0:
        return 1, 0, sign
    return (1 if sign > 0 else -1), 1, sign


def _symmetry_orientation(gx: int, gy: int, cross: int) -> tuple[int, int]:
    slope = _f32(1_000_000.0) if gy == 0 else _f32(_f32(float(gx)) / _f32(float(gy)))
    if slope < 0.5:
        return 0, 1
    if slope > 2.0:
        return 1, 0
    return (-1, 1) if cross > 0 else (1, 1)


def _is_edge_maximum(response: Sequence[int], side: int, y: int, x: int, a: int, b: int) -> bool:
    strength = response[y * side + x]
    return (
        strength > response[(y + a) * side + x + b]
        and strength >= response[(y - a) * side + x - b]
        and strength > response[(y + 2 * a) * side + x + 2 * b]
        and strength >= response[(y - 2 * a) * side + x - 2 * b]
    )


def _thin_edges(response: list[int], middle: list[int], side: int) -> None:
    y = 4
    while y < side - 4:
        x = 4
        while x < side - 4:
            at = y * side + x
            if middle[at] < 8:
                center_strength = response[at]
                points = (
                    (y - 1, x - 1), (y - 1, x), (y - 1, x + 1),
                    (y, x - 1),                         (y, x + 1),
                    (y + 1, x - 1), (y + 1, x), (y + 1, x + 1),
                )
                neighbor_count = sum(middle[py * side + px] < 8 for py, px in points)

                if neighbor_count == 0:
                    middle[at] = 100

                if neighbor_count == 1 and middle[at] < 6:
                    values = [
                        response[(y - 1) * side + x - 1],
                        response[(y - 1) * side + x],
                        response[(y - 1) * side + x + 1],
                        response[y * side + x - 1],
                        0,
                        response[y * side + x + 1],
                        response[(y + 1) * side + x - 1],
                        response[(y + 1) * side + x],
                        response[(y + 1) * side + x + 1],
                    ]
                    neighbors = [
                        middle[(y - 1) * side + x - 1], middle[(y - 1) * side + x], middle[(y - 1) * side + x + 1],
                        middle[y * side + x - 1], 100, middle[y * side + x + 1],
                        middle[(y + 1) * side + x - 1], middle[(y + 1) * side + x], middle[(y + 1) * side + x + 1],
                    ]
                    active = [index for index, value in enumerate(neighbors) if value < 8]
                    if active:
                        direction = active[0]
                        multipliers = {
                            0: (0, 0, 2, 0, 1, 3, 2, 3, 4),
                            1: (0, 0, 0, 2, 0, 2, 3, 4, 3),
                            2: (2, 0, 0, 3, 1, 0, 4, 3, 2),
                            3: (0, 2, 3, 0, 1, 4, 0, 2, 3),
                            5: (3, 2, 0, 4, 1, 0, 3, 2, 0),
                            6: (2, 3, 4, 0, 1, 3, 0, 0, 2),
                            7: (3, 4, 3, 2, 1, 2, 0, 0, 0),
                            8: (4, 3, 2, 3, 1, 0, 2, 0, 0),
                        }.get(direction, (1,) * 9)
                        weighted = [values[k] * multipliers[k] for k in range(9)]
                        best = 0
                        best_row = 0
                        best_col = 0
                        for row in range(3):
                            for col in range(3):
                                value = weighted[row * 3 + col]
                                if value > best:
                                    best = value
                                    best_row = row
                                    best_col = col
                        if best > 0:
                            middle[at + best_row * side + best_col - side - 1] = (
                                4 if middle[at] < 4 else middle[at] + 1
                            )
                            if best_row + best_row + best_col < 3:
                                y += best_row - 1
                                x += best_col - 2
                                if y < 4:
                                    y = 4
                                if x < 4:
                                    x = 4

                if neighbor_count == 2:
                    b00 = int(middle[(y - 1) * side + x - 1] < 8)
                    b02 = int(middle[(y - 1) * side + x + 1] < 8)
                    b20 = int(middle[(y + 1) * side + x - 1] < 8)
                    b22 = int(middle[(y + 1) * side + x + 1] < 8)
                    if (b00 + b02 + b20 + b22 == 2) and ((b00 | b22) & (b02 | b20)):
                        if b00:
                            move_x, move_y = ((0, -1) if b02 else (-1, 0))
                        else:
                            move_x, move_y = ((1, 0) if b02 else (0, 1))
                        neighbor = response[(y + move_y) * side + x + move_x]
                        if _f32(float(neighbor) / float(center_strength)) > 0.7:
                            if move_x == 0:
                                clear = all(
                                    middle[(y + 2 * move_y) * side + x + dx] > 7
                                    for dx in (-1, 0, 1)
                                )
                            else:
                                clear = all(
                                    middle[(y + dy) * side + x + 2 * move_x] > 7
                                    for dy in (-1, 0, 1)
                                )
                            if clear:
                                middle[at] = 100
                                middle[(y + move_y) * side + x + move_x] = 3
                    else:
                        b01 = int(middle[(y - 1) * side + x] < 8)
                        b12 = int(middle[y * side + x + 1] < 8)
                        b21 = int(middle[(y + 1) * side + x] < 8)
                        b10 = int(middle[y * side + x - 1] < 8)
                        clear_angle = (
                            ((b01 + b12 + b21 + b10) == 2)
                            and ((b10 | b12) & (b01 | b21))
                            and (
                                (b01 and (middle[(y - 2) * side + x - 1] < 8 or middle[(y - 2) * side + x + 1] < 8))
                                or (b10 and (middle[(y - 1) * side + x - 2] < 8 or middle[(y + 1) * side + x - 2] < 8))
                                or (b12 and (middle[(y - 1) * side + x + 2] < 8 or middle[(y + 1) * side + x + 2] < 8))
                                or (b21 and (middle[(y + 2) * side + x - 1] < 8 or middle[(y + 2) * side + x + 1] < 8))
                            )
                        )
                        if clear_angle:
                            middle[at] = 100
                            y -= 1
                            x -= 2
                            if y < 4:
                                y = 4
                            if x < 4:
                                x = 4

                if neighbor_count > 2:
                    b01 = int(middle[(y - 1) * side + x] < 8)
                    b12 = int(middle[y * side + x + 1] < 8)
                    b21 = int(middle[(y + 1) * side + x] < 8)
                    b10 = int(middle[y * side + x - 1] < 8)
                    if b01 + b12 + b21 + b10 > 1:
                        b00 = int(middle[(y - 1) * side + x - 1] < 8)
                        b02 = int(middle[(y - 1) * side + x + 1] < 8)
                        b20 = int(middle[(y + 1) * side + x - 1] < 8)
                        b22 = int(middle[(y + 1) * side + x + 1] < 8)
                        p1 = b00 | b01
                        p2 = b02 | b12
                        p3 = b22 | b21
                        p4 = b20 | b10
                        connected = (
                            p1 + p2 + p3 + p4
                            - (b01 & p2)
                            - (b12 & p3)
                            - (b21 & p4)
                            - (b10 & p1)
                        )
                        if connected < 2:
                            middle[at] = 100
                            y -= 1
                            x -= 2
                            if y < 4:
                                y = 4
                            if x < 4:
                                x = 4

            x += 1
        y += 1


def _susan_edges(image: list[int], side: int) -> None:
    response = [0] * (side * side)
    middle = [100] * (side * side)

    for y in range(3, side - 3):
        for x in range(3, side - 3):
            center = image[y * side + x]
            area = 100 + sum(
                _BRIGHTNESS[center - image[(y + dy) * side + x + dx] + 256]
                for dx, dy in _MASK
            )
            if area <= MAX_NO_EDGES:
                response[y * side + x] = MAX_NO_EDGES - area

    for y in range(4, side - 4):
        for x in range(4, side - 4):
            at = y * side + x
            strength = response[at]
            if strength <= 0:
                continue
            area = MAX_NO_EDGES - strength
            should_test_symmetry = area <= 600

            if area > 600:
                gx = 0
                gy = 0
                for dx, dy in _MASK:
                    value = _BRIGHTNESS[
                        image[at] - image[(y + dy) * side + x + dx] + 256
                    ]
                    gx += dx * value
                    gy += dy * value
                magnitude = _f32(math.sqrt(_f32(float(gx * gx + gy * gy))))
                if magnitude > 0.9 * float(area):
                    should_test_symmetry = False
                    a, b, _ = _edge_orientation(gx, gy)
                    if _is_edge_maximum(response, side, y, x, a, b):
                        middle[at] = 1
                else:
                    should_test_symmetry = True

            if should_test_symmetry:
                gx = 0
                gy = 0
                cross = 0
                for dx, dy in _MASK:
                    value = _BRIGHTNESS[
                        image[at] - image[(y + dy) * side + x + dx] + 256
                    ]
                    gx += dx * dx * value
                    gy += dy * abs(dy) * value
                    cross += dx * dy * value
                a, b = _symmetry_orientation(gx, gy, cross)
                if _is_edge_maximum(response, side, y, x, a, b):
                    middle[at] = 2

    _thin_edges(response, middle, side)

    for y in range(side):
        for x in range(side):
            if middle[y * side + x] < 8:
                for dy in (-1, 0, 1):
                    for dx in (-1, 0, 1):
                        image[(y + dy) * side + x + dx] = 255
    for at, marker in enumerate(middle):
        if marker < 8:
            image[at] = 0


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
    _susan_edges(image, side)
    return side * side, bytes(image)
