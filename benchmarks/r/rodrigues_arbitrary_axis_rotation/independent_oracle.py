"""Matrix-form independent reference for arbitrary-axis finite rotation."""

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


def _valid(values: Sequence[object], input_is_null: bool, input_length: int | None):
    if type(input_is_null) is not bool or type(values) not in (list, tuple):
        return None
    declared = len(values) if input_length is None else input_length
    if (type(declared) is not int or declared != len(values) or input_is_null
            or declared != 7):
        return None
    converted: list[float] = []
    for value in values:
        if type(value) not in (float, int):
            return None
        number = float(value)
        if not math.isfinite(number):
            return None
        converted.append(number)
    if any(abs(converted[i]) > COMPONENT_LIMIT for i in range(6)):
        return None
    axis = converted[:3]
    magnitude = max(abs(axis[0]), abs(axis[1]), abs(axis[2]))
    if magnitude == 0.0 or abs(converted[6]) > ANGLE_LIMIT:
        return None
    qx, qy, qz = (axis[0] / magnitude, axis[1] / magnitude, axis[2] / magnitude)
    denominator = math.sqrt(qx * qx + qy * qy + qz * qz)
    if not math.isfinite(denominator) or denominator == 0.0:
        return None
    return (qx / denominator, qy / denominator, qz / denominator), converted[3:6], converted[6]


def expected_output(
    values: Sequence[object],
    output_capacity: int | None = None,
    output_is_null: bool = False,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> tuple[int, list[float]]:
    parsed = _valid(values, input_is_null, input_length)
    if parsed is None:
        return -1, []
    (x, y, z), vector, theta = parsed
    vx, vy, vz = vector
    c, s = math.cos(theta), math.sin(theta)
    d = 1.0 - c
    matrix = (
        (c + x * x * d, x * y * d - z * s, x * z * d + y * s),
        (y * x * d + z * s, c + y * y * d, y * z * d - x * s),
        (z * x * d - y * s, z * y * d + x * s, c + z * z * d),
    )
    result = [
        (matrix[0][0] * vx + matrix[0][1] * vy) + matrix[0][2] * vz,
        (matrix[1][0] * vx + matrix[1][1] * vy) + matrix[1][2] * vz,
        (matrix[2][0] * vx + matrix[2][1] * vy) + matrix[2][2] * vz,
    ]
    if any(not math.isfinite(value) or abs(value) > OUTPUT_LIMIT for value in result):
        return -1, []
    if type(output_is_null) is not bool:
        return -1, []
    if output_is_null or (output_capacity is not None and
                          (type(output_capacity) is not int or output_capacity < 3)):
        return -2, []
    return 3, result
