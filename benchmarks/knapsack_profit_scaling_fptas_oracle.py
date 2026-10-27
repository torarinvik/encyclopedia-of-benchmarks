"""Reference implementation for the bounded Ibarra--Kim profit-scaling profile."""

from __future__ import annotations

import struct
from collections.abc import Sequence
from fractions import Fraction

MAX_N = 12
MAX_CAPACITY = 100
MAX_WEIGHT = 100
MAX_PROFIT = 10_000
MAX_INPUT_LENGTH = 2 + 2 * MAX_N
MAX_OUTPUT_BYTES = 16


def _parse(values: Sequence[int] | None) -> tuple[int, tuple[tuple[int, int], ...]] | None:
    if (not isinstance(values, (list, tuple)) or len(values) < 4
            or len(values) > MAX_INPUT_LENGTH
            or any(type(v) is not int or not -(1 << 63) <= v < (1 << 63) for v in values)):
        return None
    capacity, n = values[:2]
    if not 1 <= capacity <= MAX_CAPACITY or not 1 <= n <= MAX_N or len(values) != 2 + 2 * n:
        return None
    items = tuple((values[2 + 2 * i], values[3 + 2 * i]) for i in range(n))
    if any(not 1 <= w <= MAX_WEIGHT or not 1 <= p <= MAX_PROFIT for w, p in items):
        return None
    return capacity, items


def _lp_upper_bound(capacity: int, items: tuple[tuple[int, int], ...]) -> int:
    # Items heavier than the capacity can never occur in an integral solution.
    order = sorted((i for i, (w, _) in enumerate(items) if w <= capacity),
                   key=lambda i: (-Fraction(items[i][1], items[i][0]), i))
    remaining = capacity
    whole_profit = 0
    for i in order:
        weight, profit = items[i]
        if weight <= remaining:
            whole_profit += profit
            remaining -= weight
        else:
            whole_profit += (profit * remaining) // weight
            break
    return whole_profit


def _scaled_values(capacity: int, items: tuple[tuple[int, int], ...]) -> tuple[int, ...]:
    n = len(items)
    upper = _lp_upper_bound(capacity, items)
    if upper == 0:
        return (0,) * n
    return tuple((4 * n * profit) // upper if weight <= capacity else 0
                 for weight, profit in items)


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
    parsed = _parse(values)
    if parsed is None:
        return -1, b""
    capacity_value, items = parsed
    if output_is_null or capacity is not None and capacity < MAX_OUTPUT_BYTES:
        return -2, b""
    n = len(items)
    scaled = _scaled_values(capacity_value, items)
    max_scaled = 4 * n * n
    infinity = capacity_value + 1
    weights = [infinity] * (max_scaled + 1)
    masks = [0] * (max_scaled + 1)
    weights[0] = 0
    reachable = 0
    for i, ((weight, _), value) in enumerate(zip(items, scaled)):
        if value == 0:
            continue
        for total in range(reachable, -1, -1):
            if weights[total] <= capacity_value:
                new_total = total + value
                new_weight = weights[total] + weight
                new_mask = masks[total] | (1 << i)
                if (new_weight < weights[new_total]
                        or new_weight == weights[new_total] and new_mask < masks[new_total]):
                    weights[new_total] = new_weight
                    masks[new_total] = new_mask
        reachable = min(max_scaled, reachable + value)
    best_scaled = max(q for q, w in enumerate(weights) if w <= capacity_value)
    selected = masks[best_scaled]
    original_profit = sum(p for i, (_, p) in enumerate(items) if selected >> i & 1)
    payload = struct.pack("<qq", selected, original_profit)
    return MAX_OUTPUT_BYTES, payload
