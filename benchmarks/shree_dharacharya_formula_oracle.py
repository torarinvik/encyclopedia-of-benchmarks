"""Oracle for the pinned MATLAB Shree Dharacharya root pair."""

from __future__ import annotations

import math
import struct
from typing import Sequence


MAX_COEFFICIENT = 1_000_000
MAX_INPUT_LENGTH = 3
MAX_PARSEABLE_INPUT_LENGTH = MAX_INPUT_LENGTH + 1
MAX_OUTPUT_BYTES = 16


def expected_output(
    values: Sequence[int],
    output_capacity: int | None = None,
    output_is_null: bool = False,
) -> tuple[int, bytes]:
    """Return the two roots in source order as little-endian binary64 values."""
    if (
        not isinstance(values, (tuple, list))
        or len(values) > MAX_PARSEABLE_INPUT_LENGTH
        or any(type(value) is not int or not -(2**63) <= value < 2**63 for value in values)
    ):
        return -1, b""
    if len(values) != MAX_INPUT_LENGTH:
        return -1, b""

    a, b, c = values
    if (a == 0 or any(not -MAX_COEFFICIENT <= value <= MAX_COEFFICIENT
                      for value in (a, b, c))):
        return -1, b""
    discriminant = b * b - 4 * a * c
    if discriminant < 0:
        return -1, b""

    root = math.sqrt(float(discriminant))
    denominator = 2.0 * a
    roots = ((-b + root) / denominator, (-b - root) / denominator)
    output = struct.pack("<dd", *roots)

    if type(output_is_null) is not bool:
        return -1, b""
    if output_capacity is not None and (type(output_capacity) is not int
                                        or output_capacity < 0):
        return -1, b""
    if output_is_null or (output_capacity is not None and output_capacity < len(output)):
        return -2, b""
    return len(output), output
