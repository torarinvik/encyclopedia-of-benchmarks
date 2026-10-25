"""Independent oracle for the bounded DIS R-tree consistentKey predicate."""
from __future__ import annotations

from collections.abc import Sequence

INPUT_LENGTH = 16
MAX_PARSEABLE_INPUT_LENGTH = 17
MIN_COORDINATE = -8
MAX_COORDINATE = 8
INVALID_RESULT = -1


def expected_result(values: Sequence[int] | None, *, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    if type(input_is_null) is not bool or input_is_null or values is None:
        return INVALID_RESULT
    if not isinstance(values, (list, tuple)) or not 1 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH:
        return INVALID_RESULT
    if input_length is not None and (type(input_length) is not int or input_length != len(values)):
        return INVALID_RESULT
    if any(type(x) is not int or not -(2**63) <= x < 2**63 for x in values):
        return INVALID_RESULT
    if len(values) != INPUT_LENGTH:
        return INVALID_RESULT
    for box_at in (0, 8):
        for d in range(4):
            lo, hi = values[box_at + d], values[box_at + 4 + d]
            if not MIN_COORDINATE <= lo <= MAX_COORDINATE or not MIN_COORDINATE <= hi <= MAX_COORDINATE or lo > hi:
                return INVALID_RESULT
    # DIS consistentKey treats touching faces as intersection; separation is strict.
    for d in range(4):
        if values[d] > values[12 + d] or values[8 + d] > values[4 + d]:
            return 0
    return 1


oracle = expected_result
