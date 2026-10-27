"""Primary direct-simulation oracle for the chapter's coupon-collection process."""

from __future__ import annotations

import struct
from collections.abc import Sequence

MAX_N = 8
MAX_COUPONS = 8
MAX_STEPS = 8
MAX_INPUT = 76


def _decode(values: Sequence[int] | None):
    if (not isinstance(values, (tuple, list)) or not 4 <= len(values) <= MAX_INPUT
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return None
    n, coupons, copies, steps = values[:4]
    if (not 2 <= n <= MAX_N or not 1 <= coupons <= MAX_COUPONS
            or not 1 <= copies <= n or not 1 <= steps <= MAX_STEPS
            or len(values) != 4 + n + n * steps):
        return None
    full = (1 << coupons) - 1
    bins = list(values[4:4 + n])
    if any(mask < 0 or mask & ~full for mask in bins):
        return None
    for coupon in range(coupons):
        if sum(1 for mask in bins if mask & (1 << coupon)) < copies:
            return None
    tape = list(values[4 + n:])
    if any(bit not in (0, 1) for bit in tape):
        return None
    return n, coupons, copies, steps, bins, tape


def _solve(parsed):
    n, _coupons, _copies, steps, bins, tape = parsed
    collected = 0
    singleton_steps = 0
    for step in range(steps):
        opened = [bin_index for bin_index in range(n) if tape[step * n + bin_index] == 1]
        if len(opened) == 1:
            singleton_steps += 1
            collected |= bins[opened[0]]
    return collected, singleton_steps


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or capacity is not None and (type(capacity) is not int or capacity < 0)
            or input_length is not None and (type(input_length) is not int or not 0 <= input_length <= MAX_INPUT)
            or input_is_null and values not in (None, [], ())
            or not input_is_null and values is not None and input_length is not None
            and input_length != len(values)):
        return -1, b""
    if input_is_null or values is None:
        return -1, b""
    parsed = _decode(values)
    if parsed is None:
        return -1, b""
    collected, singleton_steps = _solve(parsed)
    payload = struct.pack("<qq", collected, singleton_steps)
    if output_is_null or capacity is not None and capacity < len(payload):
        return -2, b""
    return len(payload), payload
