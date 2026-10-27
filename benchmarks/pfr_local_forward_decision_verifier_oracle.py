"""Independent cutoff-based verifier for the bounded PFR local decision."""

from __future__ import annotations

import struct
from collections.abc import Sequence


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or capacity is not None and (type(capacity) is not int or capacity < 0)
            or input_length is not None and (type(input_length) is not int or not 0 <= input_length <= 2)
            or input_is_null and values not in (None, [], ())
            or not input_is_null and values is not None and input_length is not None
            and input_length != len(values)):
        return -1, b""
    if input_is_null or not isinstance(values, (list, tuple)) or len(values) != 2:
        return -1, b""
    angle, draw = values
    if (any(type(value) is not int or not -(1 << 63) <= value < (1 << 63) for value in values)
            or not 0 <= angle <= 180_000_000
            or not 0 <= draw < 1_000_000):
        return -1, b""
    if angle >= 134_000_000:
        answer = 1
    else:
        # Number of integer grid points d satisfying d < angle/180.
        winning_draw_count = (angle + 179) // 180
        answer = int(draw < winning_draw_count)
    if output_is_null or capacity is not None and capacity < 8:
        return -2, b""
    return 8, struct.pack("<q", answer)
