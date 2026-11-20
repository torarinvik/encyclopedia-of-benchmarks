"""Geometric CORDIC reference independent of the fixed-point register update."""

from __future__ import annotations

import math
import struct

Q = 1_000_000_000
QUARTER_TURN = 1_570_796_327
ROTATION_ANGLES = (
    785_398_163, 463_647_609, 244_978_663, 124_354_995, 62_418_810,
    31_239_833, 15_623_729, 7_812_341, 3_906_230, 1_953_123,
    976_562, 488_281, 244_141, 122_070, 61_035,
)
ANGLE_LIMIT = 3_141_592_653
OUTPUT_SIZE = 24
MAX_PARSEABLE_INPUT_VALUES = 3
WORKSPACE_BYTES = 128


def expected_output(
    values: list[int] | tuple[int, ...] | None,
    output_capacity: int | None = None,
    output_is_null: bool = False,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> tuple[int, bytes]:
    """Use the signed-angle sum and gain product, not integer x/y recurrences."""
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or output_capacity is not None
            and (type(output_capacity) is not int or output_capacity < 0)
            or input_length is not None
            and (type(input_length) is not int
                 or not 0 <= input_length <= MAX_PARSEABLE_INPUT_VALUES)):
        return -1, b""
    if input_is_null:
        if values not in (None, [], ()) or input_length not in (None, 0):
            return -1, b""
        return -1, b""
    if (not isinstance(values, (list, tuple))
            or input_length is not None and input_length != len(values)
            or len(values) != 2
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return -1, b""
    angle, stages = values
    if not -ANGLE_LIMIT <= angle <= ANGLE_LIMIT or not 1 <= stages <= 16:
        return -1, b""
    if output_is_null or (output_capacity is not None and output_capacity < OUTPUT_SIZE):
        return -2, b""

    residual = angle
    first_direction = 1 if residual >= 0 else -1
    residual -= first_direction * QUARTER_TURN
    accumulated = first_direction * QUARTER_TURN
    gain = 1.0
    for shift, alpha in enumerate(ROTATION_ANGLES[:stages - 1]):
        direction = 1 if residual >= 0 else -1
        residual -= direction * alpha
        accumulated += direction * alpha
        gain *= math.sqrt(1.0 + 2.0 ** (-2 * shift))

    radians = accumulated / Q
    values_out = (
        gain * math.cos(radians),
        gain * math.sin(radians),
        residual / Q,
    )
    return OUTPUT_SIZE, struct.pack("<3d", *values_out)
