"""Vector-form reference for a bounded finite rotation about an arbitrary axis."""

from __future__ import annotations

import math
from typing import Sequence

MAX_PARSEABLE_INPUT_LENGTH = 8
MAX_INPUT_LENGTH = MAX_PARSEABLE_INPUT_LENGTH
MAX_VALID_INPUT_LENGTH = 7
MAX_OUTPUT_ELEMENTS = 3
WORKSPACE_BYTES = 256
ABSOLUTE_TOLERANCE = 1e-9
RELATIVE_TOLERANCE = 2e-12
ANGLE_LIMIT = 6.283185307179586
COMPONENT_LIMIT = 1_000_000.0
OUTPUT_LIMIT = 2_000_000.0


def _finite_number(value: object) -> bool:
    return type(value) in (int, float) and math.isfinite(float(value))


def _input(values: Sequence[object], input_is_null: bool, input_length: int | None):
    if type(input_is_null) is not bool or type(values) not in (list, tuple):
        return None
    length = len(values) if input_length is None else input_length
    if type(length) is not int or length != len(values) or input_is_null or length != 7:
        return None
    if not all(_finite_number(value) for value in values):
        return None
    a = [float(values[index]) for index in range(3)]
    v = [float(values[index + 3]) for index in range(3)]
    theta = float(values[6])
    if any(abs(value) > COMPONENT_LIMIT for value in a + v):
        return None
    scale = max(abs(value) for value in a)
    if scale == 0.0 or abs(theta) > ANGLE_LIMIT:
        return None
    scaled = [value / scale for value in a]
    norm = math.sqrt((scaled[0] * scaled[0] + scaled[1] * scaled[1]) + scaled[2] * scaled[2])
    if not math.isfinite(norm) or norm == 0.0:
        return None
    axis = [value / norm for value in scaled]
    return axis, v, theta


def expected_output(
    values: Sequence[object],
    output_capacity: int | None = None,
    output_is_null: bool = False,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> tuple[int, list[float]]:
    parsed = _input(values, input_is_null, input_length)
    if parsed is None:
        return -1, []
    axis, vector, theta = parsed
    nx, ny, nz = axis
    vx, vy, vz = vector
    cosine = math.cos(theta)
    sine = math.sin(theta)
    one_minus_cosine = 1.0 - cosine
    cross = [ny * vz - nz * vy, nz * vx - nx * vz, nx * vy - ny * vx]
    dot = (nx * vx + ny * vy) + nz * vz
    result = [
        (vx * cosine + cross[0] * sine) + (nx * dot) * one_minus_cosine,
        (vy * cosine + cross[1] * sine) + (ny * dot) * one_minus_cosine,
        (vz * cosine + cross[2] * sine) + (nz * dot) * one_minus_cosine,
    ]
    if any(not math.isfinite(value) or abs(value) > OUTPUT_LIMIT for value in result):
        return -1, []
    if type(output_is_null) is not bool:
        return -1, []
    if output_is_null or (output_capacity is not None and
                          (type(output_capacity) is not int or output_capacity < 3)):
        return -2, []
    return 3, result
