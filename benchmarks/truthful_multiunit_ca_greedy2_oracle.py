"""Primary oracle for the chapter's bounded Greedy-2 CA profile."""
from __future__ import annotations

from collections.abc import Sequence
import math

MAX_ITEMS = 6
MAX_BIDDERS = 12
MAX_INPUT = 32
MAX_OUTPUT = 104
EULER = 2.718281828459045


def _parse(values, input_is_null, input_length):
    if (input_is_null or not isinstance(values, (list, tuple)) or len(values) < 5 or len(values) > MAX_INPUT
            or (input_length is not None and (type(input_length) is not int or input_length != len(values)))
            or any(type(x) is not int or not -(1 << 63) <= x < (1 << 63) for x in values)):
        return None
    items, bidders = values[:2]
    if not 2 <= items <= MAX_ITEMS or not 1 <= bidders <= MAX_BIDDERS or len(values) != 2 + items + 2 * bidders:
        return None
    capacities = tuple(values[2:2 + items])
    if any(not 1 <= x <= 8 for x in capacities):
        return None
    bids = []
    limit = 1 << items
    for i in range(bidders):
        value, mask = values[2 + items + 2*i:4 + items + 2*i]
        if not 1 <= value <= 100 or not 1 <= mask < limit:
            return None
        bids.append((value, mask))
    return items, capacities, bids


def _solve(parsed):
    items, capacities, bids = parsed
    minimum = min(capacities)
    threshold = math.pow(EULER, minimum) * items
    prices = [1.0 / cap for cap in capacities]
    selected = []
    remaining = set(range(len(bids)))
    while remaining:
        best = None
        best_score = -1.0
        for i, (value, mask) in enumerate(bids):
            if i not in remaining:
                continue
            denominator = sum(prices[e] for e in range(items) if mask & (1 << e))
            score = value / denominator
            if best is None or score > best_score:
                best, best_score = i, score
        if best is None:
            break
        selected.append(best)
        remaining.remove(best)
        mask = bids[best][1]
        for e, cap in enumerate(capacities):
            if mask & (1 << e):
                prices[e] *= math.pow(threshold, 1.0 / cap)
        if sum(cap * prices[e] for e, cap in enumerate(capacities)) >= threshold:
            break
    return [len(selected), *selected]


def expected_output(values: Sequence[int] | None, output_capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if type(output_is_null) is not bool or type(input_is_null) is not bool:
        return -1, b""
    parsed = _parse(values, input_is_null, input_length)
    if parsed is None:
        return -1, b""
    result = _solve(parsed)
    payload = b"".join(x.to_bytes(8, "little", signed=True) for x in result)
    if output_capacity is not None and (type(output_capacity) is not int or output_capacity < 0):
        return -1, b""
    if output_is_null or output_capacity is not None and output_capacity < len(payload):
        return -2, b""
    return len(payload), payload
