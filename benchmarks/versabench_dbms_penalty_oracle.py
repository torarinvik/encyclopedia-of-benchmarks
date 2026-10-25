"""Independent oracle for the bounded VersaBench 4D R-tree penalty helper."""
from __future__ import annotations

from collections.abc import Sequence

INPUT_LENGTH = 16
MAX_PARSEABLE_INPUT_LENGTH = 17
MIN_COORDINATE = -8
MAX_COORDINATE = 8
INVALID_RESULT = -1


def expected_result(values: Sequence[int] | None, *, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    if (type(input_is_null) is not bool or input_is_null or values is None
            or not isinstance(values, (list, tuple))
            or not 1 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
            or (input_length is not None and
                (type(input_length) is not int or input_length != len(values)))
            or any(type(v) is not int or not -(1 << 63) <= v < (1 << 63) for v in values)
            or len(values) != INPUT_LENGTH):
        return INVALID_RESULT
    boxes = []
    for base in (0, 8):
        lo = tuple(values[base:base+4])
        hi = tuple(values[base+4:base+8])
        if any(not MIN_COORDINATE <= x <= MAX_COORDINATE for x in (*lo, *hi)):
            return INVALID_RESULT
        if any(a >= b for a, b in zip(lo, hi)):
            return INVALID_RESULT
        boxes.append((lo, hi))

    a_lo, a_hi = boxes[0]
    b_lo, b_hi = boxes[1]
    union_volume = 1
    original_volume = 1
    for d in range(4):
        union_volume *= max(a_hi[d], b_hi[d]) - min(a_lo[d], b_lo[d])
        original_volume *= a_hi[d] - a_lo[d]
    return union_volume - original_volume


oracle = expected_result
