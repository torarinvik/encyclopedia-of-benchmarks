"""Cross-multiplication oracle for bounded weighted greedy set cover."""

from __future__ import annotations

import struct
from collections.abc import Sequence

MAX_N = 16
MAX_M = 16
MAX_INPUT = 2 + 2 * MAX_M
MAX_INPUT_LENGTH = MAX_INPUT
MAX_OUTPUT_BYTES = 8 * (MAX_M + 1)


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or capacity is not None and (type(capacity) is not int or capacity < 0)
            or input_length is not None and
            (type(input_length) is not int or not 0 <= input_length <= MAX_INPUT)
            or input_is_null and values not in (None, [], ())
            or not input_is_null and values is not None and input_length is not None
            and isinstance(values, (list, tuple)) and input_length != len(values)):
        return -1, b""
    if input_is_null or values is None or not isinstance(values, (list, tuple)):
        return -1, b""
    if (len(values) < 4 or len(values) > MAX_INPUT or any(
            type(value) is not int or not -(1 << 63) <= value < (1 << 63)
            for value in values)):
        return -1, b""
    n, m = values[0], values[1]
    if not 1 <= n <= MAX_N or not 1 <= m <= MAX_M or len(values) != 2 + 2 * m:
        return -1, b""
    weights = values[2:2 + m]
    masks = values[2 + m:]
    full = (1 << n) - 1
    if any(not 0 <= weight <= 10000 for weight in weights):
        return -1, b""
    if any(mask < 0 or mask & ~full for mask in masks):
        return -1, b""
    union = 0
    for mask in masks:
        union |= mask
    if union != full:
        return -1, b""

    covered = 0
    chosen: list[int] = []
    while covered != full:
        best = -1
        best_gain = 0
        for index, mask in enumerate(masks):
            gain = (mask & ~covered).bit_count()
            if gain == 0:
                continue
            if (best == -1 or weights[index] * best_gain < weights[best] * gain):
                best = index
                best_gain = gain
        if best == -1:
            return -1, b""
        chosen.append(best)
        covered |= masks[best]
    if output_is_null or capacity is not None and capacity < 8 * (len(chosen) + 1):
        return -2, b""
    payload = b"".join(struct.pack("<q", value) for value in (len(chosen), *chosen))
    return len(payload), payload
