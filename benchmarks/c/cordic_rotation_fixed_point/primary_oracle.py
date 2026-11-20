"""Exact fixed-point register reference for bounded CORDIC rotation."""

from __future__ import annotations

import struct

SCALE = 1_000_000_000
HALF_PI = 1_570_796_327
ANGLE_NANORADIANS = (
    785_398_163, 463_647_609, 244_978_663, 124_354_995, 62_418_810,
    31_239_833, 15_623_729, 7_812_341, 3_906_230, 1_953_123,
    976_562, 488_281, 244_141, 122_070, 61_035,
)
MIN_ANGLE = -3_141_592_653
MAX_ANGLE = 3_141_592_653
MIN_STAGES = 1
MAX_STAGES = 16
MAX_INPUT_VALUES = 2
MAX_PARSEABLE_INPUT_VALUES = 3
MAX_OUTPUT_BYTES = 24
WORKSPACE_BYTES = 128


def _rotate(angle: int, stages: int) -> tuple[int, int, int]:
    x, y, z = SCALE, 0, angle
    direction = 1 if z >= 0 else -1
    x, y = (-y, x) if direction == 1 else (y, -x)
    z -= direction * HALF_PI
    for shift in range(stages - 1):
        direction = 1 if z >= 0 else -1
        divisor = 1 << shift
        # Python // is floor division, matching a signed two's-complement shift.
        shifted_y = y // divisor
        shifted_x = x // divisor
        x, y, z = (
            x - direction * shifted_y,
            y + direction * shifted_x,
            z - direction * ANGLE_NANORADIANS[shift],
        )
    return x, y, z


def expected_output(
    values: list[int] | tuple[int, ...] | None,
    output_capacity: int | None = None,
    output_is_null: bool = False,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> tuple[int, bytes]:
    """Return `(status-or-byte-count, little-endian f64 payload)` for a call."""
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
            or len(values) < 2
            or len(values) > MAX_PARSEABLE_INPUT_VALUES
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return -1, b""
    if len(values) != 2:
        return -1, b""
    angle, stages = values
    if not MIN_ANGLE <= angle <= MAX_ANGLE or not MIN_STAGES <= stages <= MAX_STAGES:
        return -1, b""
    if output_is_null or (output_capacity is not None and output_capacity < MAX_OUTPUT_BYTES):
        return -2, b""
    x, y, z = _rotate(angle, stages)
    payload = struct.pack("<3d", x / SCALE, y / SCALE, z / SCALE)
    return MAX_OUTPUT_BYTES, payload
