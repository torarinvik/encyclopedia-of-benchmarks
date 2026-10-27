"""Primary integer oracle for the bounded PFR local forwarding decision."""

from __future__ import annotations

import struct
from collections.abc import Sequence

MAX_INPUT_LENGTH = 2
MAX_OUTPUT_BYTES = 8
MAX_ANGLE_MICRODEGREES = 180_000_000
DRAW_COUNT = 1_000_000
FORWARD_THRESHOLD_MICRODEGREES = 134_000_000


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or capacity is not None and (type(capacity) is not int or capacity < 0)
            or input_length is not None and (type(input_length) is not int
                                             or not 0 <= input_length <= MAX_INPUT_LENGTH)
            or input_is_null and values not in (None, [], ())
            or not input_is_null and values is not None and input_length is not None
            and input_length != len(values)):
        return -1, b""
    if input_is_null or values is None or not isinstance(values, (list, tuple)) or len(values) != 2:
        return -1, b""
    if any(type(value) is not int or not -(1 << 63) <= value < (1 << 63) for value in values):
        return -1, b""
    angle, draw = values
    if not 0 <= angle <= MAX_ANGLE_MICRODEGREES or not 0 <= draw < DRAW_COUNT:
        return -1, b""
    answer = int(angle >= FORWARD_THRESHOLD_MICRODEGREES or 180 * draw < angle)
    if output_is_null or capacity is not None and capacity < MAX_OUTPUT_BYTES:
        return -2, b""
    return MAX_OUTPUT_BYTES, struct.pack("<q", answer)
