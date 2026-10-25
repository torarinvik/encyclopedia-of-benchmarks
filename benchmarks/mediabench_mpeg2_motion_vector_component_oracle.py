"""Independent oracle for MSSG MPEG-2 motion-vector component decoding."""
from __future__ import annotations

from collections.abc import Sequence
import struct

MAX_INPUT_LENGTH = 4
MAX_PARSEABLE_INPUT_LENGTH = 5
MAX_OUTPUT_BYTES = 8


def expected_output(values: Sequence[int] | None,
                    output_capacity: int | None = MAX_OUTPUT_BYTES,
                    output_is_null: bool = False,
                    input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if (type(input_is_null) is not bool or input_is_null or values is None
            or not isinstance(values, (list, tuple))
            or not 1 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
            or (input_length is not None and
                (type(input_length) is not int or input_length != len(values)))
            or any(type(x) is not int or not -(1 << 63) <= x < (1 << 63) for x in values)):
        return -1, b""
    if len(values) != MAX_INPUT_LENGTH:
        return -1, b""
    predictor, r_size, motion_code, residual = values
    if not 0 <= r_size <= 6 or not -16 <= motion_code <= 16:
        return -1, b""
    limit = 16 << r_size
    if not -limit <= predictor < limit:
        return -1, b""
    if motion_code == 0 or r_size == 0:
        if residual != 0:
            return -1, b""
    elif not 0 <= residual < (1 << r_size):
        return -1, b""

    vector = predictor
    if motion_code > 0:
        vector += ((motion_code - 1) << r_size) + residual + 1
        if vector >= limit:
            vector -= 2 * limit
    elif motion_code < 0:
        vector -= ((-motion_code - 1) << r_size) + residual + 1
        if vector < -limit:
            vector += 2 * limit
    output = struct.pack("<q", vector)
    if type(output_is_null) is not bool or type(output_capacity) is not int or output_capacity < 0:
        return -1, b""
    if output_is_null or output_capacity < len(output):
        return -2, b""
    return len(output), output


oracle = expected_output
