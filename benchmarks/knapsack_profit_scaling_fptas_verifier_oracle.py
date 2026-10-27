"""Independent exhaustive verifier for the profit-scaling knapsack profile."""

from __future__ import annotations

import struct
from collections.abc import Sequence
from fractions import Fraction

MAX_N = 12
MAX_INPUT_LENGTH = 2 + 2 * MAX_N
MAX_OUTPUT_BYTES = 16


def _decode(data: Sequence[int] | None):
    if (not isinstance(data, (list, tuple)) or len(data) < 4 or len(data) > MAX_INPUT_LENGTH
            or any(type(x) is not int or not -(1 << 63) <= x < (1 << 63) for x in data)):
        return None
    cap, n = data[0], data[1]
    if not 1 <= cap <= 100 or not 1 <= n <= MAX_N or len(data) != 2 + 2 * n:
        return None
    items = [(data[2 + 2 * i], data[3 + 2 * i]) for i in range(n)]
    if any(not 1 <= w <= 100 or not 1 <= p <= 10_000 for w, p in items):
        return None
    return cap, items


def _fractional_bound(cap: int, items: list[tuple[int, int]]) -> int:
    order = sorted((i for i, (w, _) in enumerate(items) if w <= cap),
                   key=lambda i: (-Fraction(items[i][1], items[i][0]), i))
    room, total = cap, 0
    for i in order:
        w, p = items[i]
        if w <= room:
            total += p
            room -= w
        else:
            total += p * room // w
            break
    return total


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or capacity is not None and (type(capacity) is not int or capacity < 0)
            or input_length is not None and
            (type(input_length) is not int or not 0 <= input_length <= MAX_INPUT_LENGTH)
            or input_is_null and values not in (None, [], ())
            or not input_is_null and values is not None and input_length is not None
            and isinstance(values, (list, tuple)) and input_length != len(values)):
        return -1, b""
    if input_is_null or values is None:
        return -1, b""
    parsed = _decode(values)
    if parsed is None:
        return -1, b""
    cap, items = parsed
    if output_is_null or capacity is not None and capacity < MAX_OUTPUT_BYTES:
        return -2, b""
    n = len(items)
    upper = _fractional_bound(cap, items)
    scaled = [4 * n * p // upper if upper and w <= cap else 0 for w, p in items]
    best_key = (-1, cap + 1, 0)
    for mask in range(1 << n):
        weight = sum(items[i][0] for i in range(n) if mask >> i & 1)
        if weight > cap:
            continue
        scaled_profit = sum(scaled[i] for i in range(n) if mask >> i & 1)
        key = (scaled_profit, -weight, -mask)
        if key > best_key:
            best_key = key
            best_mask = mask
    original_profit = sum(items[i][1] for i in range(n) if best_mask >> i & 1)
    return MAX_OUTPUT_BYTES, struct.pack("<qq", best_mask, original_profit)
