"""Independent oracle for the bounded VersaBench 4D keysUnion helper."""
from __future__ import annotations

from collections.abc import Sequence
import struct

MAX_COUNT = 16
MAX_INPUT_LENGTH = 1 + 8 * MAX_COUNT
MAX_PARSEABLE_INPUT_LENGTH = MAX_INPUT_LENGTH + 1
MAX_OUTPUT_BYTES = 64


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
            or any(type(v) is not int or not -(1 << 63) <= v < (1 << 63) for v in values)):
        return -1, b""
    count = values[0]
    if not 1 <= count <= MAX_COUNT or len(values) != 1 + 8 * count:
        return -1, b""

    lower = list(values[1:5])
    upper = list(values[5:9])
    for i in range(count):
        at = 1 + 8 * i
        box_lower = values[at:at+4]
        box_upper = values[at+4:at+8]
        if any(not -8 <= x <= 8 for x in (*box_lower, *box_upper)):
            return -1, b""
        if any(lo > hi for lo, hi in zip(box_lower, box_upper)):
            return -1, b""
        for d in range(4):
            lower[d] = min(lower[d], box_lower[d])
            upper[d] = max(upper[d], box_upper[d])

    if type(output_is_null) is not bool or type(output_capacity) is not int or output_capacity < 0:
        return -1, b""
    if output_is_null or output_capacity < MAX_OUTPUT_BYTES:
        return -2, b""
    return MAX_OUTPUT_BYTES, struct.pack("<8q", *(lower + upper))


oracle = expected_output
