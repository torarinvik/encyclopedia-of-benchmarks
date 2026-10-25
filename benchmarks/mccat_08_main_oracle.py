"""Independent oracle for McCat 08-main's bounded object-transform loop."""

from __future__ import annotations

import math
from collections.abc import Sequence

MIN_POINTS = 1
MAX_POINTS = 16
MIN_FRAMES = 1
MAX_FRAMES = 360
HEADER_WORDS = 20
MAX_INPUT_LENGTH = HEADER_WORDS + 3 * MAX_POINTS
MICRO = 1_000_000
SOURCE_PI = 3.14159265359
COORD_LIMIT = 100 * MICRO
SCALE_LIMIT = 4 * MICRO
ANGLE_LIMIT = 360 * MICRO
INVALID_RESULT = -1


def _decode(values: Sequence[int]) -> tuple[int, list[tuple[float, float, float]], list[float]] | None:
    if not HEADER_WORDS <= len(values) <= MAX_INPUT_LENGTH:
        return None
    frames, raw_count = values[0], values[1]
    if not MIN_FRAMES <= frames <= MAX_FRAMES or not MIN_POINTS <= raw_count <= MAX_POINTS:
        return None
    if len(values) != HEADER_WORDS + 3 * raw_count:
        return None
    scale_values = list(values[2:5]) + list(values[11:14])
    angle_values = list(values[5:8]) + list(values[14:17])
    translation_values = list(values[8:11]) + list(values[17:20])
    if any(not -SCALE_LIMIT <= v <= SCALE_LIMIT for v in scale_values):
        return None
    if any(not -ANGLE_LIMIT <= v <= ANGLE_LIMIT for v in angle_values):
        return None
    if any(not -COORD_LIMIT <= v <= COORD_LIMIT for v in translation_values):
        return None
    points: list[tuple[float, float, float]] = []
    seen: set[tuple[int, int, int]] = set()
    for index in range(raw_count):
        raw = tuple(values[HEADER_WORDS + 3 * index + axis] for axis in range(3))
        if any(not -COORD_LIMIT <= value <= COORD_LIMIT for value in raw):
            return None
        # Source InsertPoint merges points whose per-axis difference is < 1e-6.
        # Micro-unit integer inputs therefore merge exact coordinate duplicates.
        if raw not in seen:
            seen.add(raw)
            points.append(tuple(value / MICRO for value in raw))
    if not points:
        return None
    parameters = [value / MICRO for value in values[2:20]]
    return frames, points, parameters


def _matrix_product(left: list[list[float]], right: list[list[float]]) -> list[list[float]]:
    return [[sum(left[row][k] * right[k][column] for k in range(4))
             for column in range(4)] for row in range(4)]


def _scale_matrix(scale: tuple[float, float, float]) -> list[list[float]]:
    sx, sy, sz = scale
    return [[sx, 0.0, 0.0, 0.0], [0.0, sy, 0.0, 0.0],
            [0.0, 0.0, sz, 0.0], [0.0, 0.0, 0.0, 1.0]]


def _translation_matrix(translation: tuple[float, float, float]) -> list[list[float]]:
    dx, dy, dz = translation
    return [[1.0, 0.0, 0.0, dx], [0.0, 1.0, 0.0, dy],
            [0.0, 0.0, 1.0, dz], [0.0, 0.0, 0.0, 1.0]]


def _rotation_matrix(angles: tuple[float, float, float]) -> list[list[float]]:
    rx, ry, rz = (SOURCE_PI / 180.0 * angle for angle in angles)
    cx, sx = math.cos(rx), math.sin(rx)
    cy, sy = math.cos(ry), math.sin(ry)
    cz, sz = math.cos(rz), math.sin(rz)
    x = [[1.0, 0.0, 0.0, 0.0], [0.0, cx, -sx, 0.0],
         [0.0, sx, cx, 0.0], [0.0, 0.0, 0.0, 1.0]]
    y = [[cy, 0.0, sy, 0.0], [0.0, 1.0, 0.0, 0.0],
         [-sy, 0.0, cy, 0.0], [0.0, 0.0, 0.0, 1.0]]
    z = [[cz, -sz, 0.0, 0.0], [sz, cz, 0.0, 0.0],
         [0.0, 0.0, 1.0, 0.0], [0.0, 0.0, 0.0, 1.0]]
    return _matrix_product(_matrix_product(x, y), z)


def _apply(matrix: list[list[float]], point: tuple[float, float, float]) -> tuple[float, float, float]:
    vector = (*point, 1.0)
    return tuple(sum(matrix[row][column] * vector[column] for column in range(4))
                 for row in range(3))


def _round_milli(value: float) -> int:
    scaled = value * 1000.0
    return math.floor(scaled + 0.5) if scaled >= 0.0 else math.ceil(scaled - 0.5)


def expected_result(values: Sequence[int] | None,
                    input_length: int | None = None,
                    input_is_null: bool = False) -> int:
    if type(input_is_null) is not bool:
        return INVALID_RESULT
    if (input_is_null or values is None or not isinstance(values, (list, tuple))
            or len(values) > MAX_INPUT_LENGTH
            or (input_length is not None
                and (type(input_length) is not int or input_length != len(values)))
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return INVALID_RESULT
    decoded = _decode(values)
    if decoded is None:
        return INVALID_RESULT
    frames, points, p = decoded
    child_scale = tuple(p[0:3])
    child_rotation = tuple(p[3:6])
    child_translation = tuple(p[6:9])
    parent_scale = tuple(p[9:12])
    parent_rotation = tuple(p[12:15])
    parent_translation = tuple(p[15:18])
    child_scale_matrix = _scale_matrix(child_scale)
    child_rotation_matrix = _rotation_matrix(child_rotation)
    child_translation_matrix = _translation_matrix(child_translation)
    parent_scale_matrix = _scale_matrix(parent_scale)
    parent_translation_matrix = _translation_matrix(parent_translation)

    checksum = 0
    for frame in range(frames):
        root_angles = (parent_rotation[0], parent_rotation[1] + frame, parent_rotation[2])
        root_rotation_matrix = _rotation_matrix(root_angles)
        for point_index, original in enumerate(points):
            transformed = _apply(child_scale_matrix, original)
            transformed = _apply(child_rotation_matrix, transformed)
            transformed = _apply(child_translation_matrix, transformed)
            transformed = _apply(parent_scale_matrix, transformed)
            transformed = _apply(root_rotation_matrix, transformed)
            transformed = _apply(parent_translation_matrix, transformed)
            x, y, z = (_round_milli(value) for value in transformed)
            weight = (frame + 1) * (point_index + 1)
            checksum += weight * (x + 3 * y + 7 * z)
    return checksum
