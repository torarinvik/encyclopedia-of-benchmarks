"""Independent exhaustive-subset verifier for the small/large FPTAS profile."""

from __future__ import annotations

import struct
from collections.abc import Sequence
from fractions import Fraction

MAX_N = 8
MAX_INPUT_LENGTH = 2 + 2 * MAX_N
MAX_OUTPUT_BYTES = 16


def _decode(data: Sequence[int] | None):
    if (not isinstance(data, (list, tuple)) or not 4 <= len(data) <= MAX_INPUT_LENGTH
            or any(type(x) is not int or not -(1 << 63) <= x < (1 << 63) for x in data)):
        return None
    cap, n = data[:2]
    if not 1 <= cap <= 30 or not 1 <= n <= MAX_N or len(data) != 2 + 2 * n:
        return None
    items = [(data[2 + 2 * i], data[3 + 2 * i]) for i in range(n)]
    if any(not 1 <= w <= 30 or not 1 <= p <= 100 for w, p in items):
        return None
    return cap, items


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or capacity is not None and (type(capacity) is not int or capacity < 0)
            or input_length is not None and (type(input_length) is not int or not 0 <= input_length <= MAX_INPUT_LENGTH)
            or input_is_null and values not in (None, [], ())
            or not input_is_null and values is not None and input_length is not None
            and isinstance(values, (list, tuple)) and input_length != len(values)):
        return -1, b""
    if input_is_null or values is None:
        return -1, b""
    decoded = _decode(values)
    if decoded is None:
        return -1, b""
    cap, items = decoded
    if output_is_null or capacity is not None and capacity < MAX_OUTPUT_BYTES:
        return -2, b""

    n = len(items)
    ratio_order = sorted((i for i, (w, _) in enumerate(items) if w <= cap),
                         key=lambda i: (-Fraction(items[i][1], items[i][0]), i))
    room = cap
    upper = Fraction(0)
    for i in ratio_order:
        w, p = items[i]
        if w <= room:
            upper += p
            room -= w
        else:
            upper += Fraction(p * room, w)
            break
    small = [i for i, (w, p) in enumerate(items) if w <= cap and 4 * p <= upper]
    small.sort(key=lambda i: (-Fraction(items[i][1], items[i][0]), i))
    big = [i for i, (w, p) in enumerate(items) if w <= cap and 4 * p > upper]

    # Enumerate every large-item subset to recover the source DP's least weight
    # for each scaled-profit total; mask order resolves equal-weight states.
    states: dict[int, tuple[int, int]] = {0: (0, 0)}
    for subset in range(1 << len(big)):
        weight = 0
        scaled_total = 0
        mask = 0
        for j, i in enumerate(big):
            if subset >> j & 1:
                w, p = items[i]
                weight += w
                scaled_total += (16 * p * upper.denominator) // upper.numerator if upper else 0
                mask |= 1 << i
        if weight <= cap:
            old = states.get(scaled_total)
            if old is None or (weight, mask) < old:
                states[scaled_total] = (weight, mask)

    best_value, best_mask = 0, 0
    for weight, mask in states.values():
        remaining = cap - weight
        value = sum(items[i][1] for i in range(n) if mask >> i & 1)
        for i in small:
            if items[i][0] <= remaining:
                remaining -= items[i][0]
                mask |= 1 << i
                value += items[i][1]
        if value > best_value or value == best_value and mask < best_mask:
            best_value, best_mask = value, mask
    return MAX_OUTPUT_BYTES, struct.pack("<qq", best_mask, best_value)
