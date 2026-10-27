"""Independent opener-mask verifier for distributed coupon collection."""

from __future__ import annotations

import struct
from collections.abc import Sequence


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or capacity is not None and (type(capacity) is not int or capacity < 0)
            or input_length is not None and (type(input_length) is not int or not 0 <= input_length <= 76)
            or input_is_null and values not in (None, [], ())
            or not input_is_null and values is not None and input_length is not None
            and input_length != len(values)):
        return -1, b""
    if (input_is_null or not isinstance(values, (tuple, list)) or not 4 <= len(values) <= 76
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return -1, b""
    n, coupon_count, copies, steps = values[:4]
    if (not 2 <= n <= 8 or not 1 <= coupon_count <= 8 or not 1 <= copies <= n
            or not 1 <= steps <= 8 or len(values) != 4 + n + n * steps):
        return -1, b""
    full = (1 << coupon_count) - 1
    bins = values[4:4 + n]
    if any(mask < 0 or mask & ~full for mask in bins):
        return -1, b""
    for bit in range(coupon_count):
        if sum((mask >> bit) & 1 for mask in bins) < copies:
            return -1, b""
    tape = values[4 + n:]
    if any(value not in (0, 1) for value in tape):
        return -1, b""

    collected = 0
    singleton_steps = 0
    for step in range(steps):
        opened_mask = 0
        for bin_index in range(n):
            if tape[step * n + bin_index] == 1:
                opened_mask |= 1 << bin_index
        if opened_mask.bit_count() == 1:
            singleton_steps += 1
            bin_index = (opened_mask & -opened_mask).bit_length() - 1
            collected |= bins[bin_index]

    payload = struct.pack("<qq", collected, singleton_steps)
    if output_is_null or capacity is not None and capacity < len(payload):
        return -2, b""
    return len(payload), payload
