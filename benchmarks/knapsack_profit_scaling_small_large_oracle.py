"""Source-shaped Ibarra--Kim small/large profit-scaling profile."""

from __future__ import annotations

import struct
from collections.abc import Sequence
from fractions import Fraction

MAX_N = 8
MAX_CAPACITY = 30
MAX_WEIGHT = 30
MAX_PROFIT = 100
MAX_INPUT_LENGTH = 2 + 2 * MAX_N
MAX_OUTPUT_BYTES = 16
MAX_Q = 128
MAX_SCALED_PROFIT = MAX_Q


def _parse(values: Sequence[int] | None):
    if (not isinstance(values, (list, tuple)) or not 4 <= len(values) <= MAX_INPUT_LENGTH
            or any(type(v) is not int or not -(1 << 63) <= v < (1 << 63) for v in values)):
        return None
    cap, n = values[:2]
    if not 1 <= cap <= MAX_CAPACITY or not 1 <= n <= MAX_N or len(values) != 2 + 2 * n:
        return None
    items = tuple((values[2 + 2 * i], values[3 + 2 * i]) for i in range(n))
    if any(not 1 <= w <= MAX_WEIGHT or not 1 <= p <= MAX_PROFIT for w, p in items):
        return None
    return cap, items


def _upper(cap: int, items: tuple[tuple[int, int], ...]) -> Fraction:
    order = sorted((i for i, (w, _) in enumerate(items) if w <= cap),
                   key=lambda i: (-Fraction(items[i][1], items[i][0]), i))
    room = cap
    value = Fraction(0)
    for i in order:
        w, p = items[i]
        if w <= room:
            value += p
            room -= w
        else:
            value += Fraction(p * room, w)
            break
    return value


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
    parsed = _parse(values)
    if parsed is None:
        return -1, b""
    cap, items = parsed
    if output_is_null or capacity is not None and capacity < MAX_OUTPUT_BYTES:
        return -2, b""

    n = len(items)
    upper = _upper(cap, items)
    small = [i for i, (w, p) in enumerate(items) if w <= cap and 4 * p <= upper]
    large = [i for i, (w, p) in enumerate(items) if w <= cap and 4 * p > upper]
    small.sort(key=lambda i: (-Fraction(items[i][1], items[i][0]), i))
    weights = [cap + 1] * (MAX_SCALED_PROFIT + 1)
    masks = [0] * (MAX_SCALED_PROFIT + 1)
    weights[0] = 0
    reachable = 0
    for i in large:
        scaled = (16 * items[i][1] * upper.denominator) // upper.numerator if upper else 0
        for q in range(reachable, -1, -1):
            if weights[q] <= cap:
                dst = q + scaled
                nw = weights[q] + items[i][0]
                nm = masks[q] | (1 << i)
                if nw < weights[dst] or nw == weights[dst] and nm < masks[dst]:
                    weights[dst], masks[dst] = nw, nm
        reachable += scaled

    best_profit = 0
    best_mask = 0
    for q in range(reachable + 1):
        if weights[q] > cap:
            continue
        remaining = cap - weights[q]
        mask = masks[q]
        profit = sum(items[i][1] for i in range(n) if mask >> i & 1)
        for i in small:
            if items[i][0] <= remaining:
                remaining -= items[i][0]
                mask |= 1 << i
                profit += items[i][1]
        if profit > best_profit or profit == best_profit and mask < best_mask:
            best_profit, best_mask = profit, mask
    return MAX_OUTPUT_BYTES, struct.pack("<qq", best_mask, best_profit)
