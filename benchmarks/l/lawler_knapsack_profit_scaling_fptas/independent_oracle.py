"""Independent grouped-subset enumeration for Lawler's bounded FPTAS."""

from __future__ import annotations

from collections.abc import Sequence
from fractions import Fraction

MIN_ITEMS = 4
MAX_ITEMS = 8
MAX_CAPACITY = 30
MIN_PROFIT = 32
MAX_PROFIT = 200
MAX_INPUT_LENGTH = 19
MAX_SCALED_PROFIT = 32
MAX_MASK = (1 << MAX_ITEMS) - 1
MAX_RESULT = (MAX_ITEMS * MAX_PROFIT << 8) | MAX_MASK


def _parse(values: Sequence[int] | None, input_is_null: bool,
           input_length: int | None) -> tuple[int, list[tuple[int, int, int]]] | None:
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple))
            or not 2 <= len(values) <= MAX_INPUT_LENGTH
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)
            or input_length is not None
            and (type(input_length) is not int or input_length != len(values))):
        return None
    capacity, count = values[0], values[1]
    if not 1 <= capacity <= MAX_CAPACITY or not MIN_ITEMS <= count <= MAX_ITEMS:
        return None
    if len(values) != 2 + 2 * count:
        return None
    items = []
    for item_id in range(count):
        weight, profit = values[2 + 2 * item_id:4 + 2 * item_id]
        if not 1 <= weight <= capacity or not MIN_PROFIT <= profit <= MAX_PROFIT:
            return None
        items.append((item_id, weight, profit))
    return capacity, items


def _order(items: Sequence[tuple[int, int, int]]) -> list[tuple[int, int, int]]:
    return sorted(items, key=lambda item: (-Fraction(item[2], item[1]), item[0]))


def _lower_bound(capacity: int, items: Sequence[tuple[int, int, int]]) -> tuple[list, int, bool]:
    prefix = []
    used = 0
    profit = 0
    ordered = _order(items)
    for item in ordered:
        if used + item[1] > capacity:
            return prefix, max(profit, max(candidate[2] for candidate in items)), False
        prefix.append(item)
        used += item[1]
        profit += item[2]
        if used == capacity:
            return prefix, profit, True
    return prefix, profit, True


def _q(profit: int, lower_bound: int) -> int:
    for exponent in range(2):
        scale = 1 << exponent
        if scale * lower_bound < 4 * profit <= (scale << 1) * lower_bound:
            return scale * (16 * profit // (scale * lower_bound))
    return -1


def _small_prefix(capacity: int, small: Sequence[tuple[int, int, int]]) -> tuple[int, int, int]:
    mask = total_profit = used = 0
    for item in _order(small):
        if used + item[1] > capacity:
            break
        mask |= 1 << item[0]
        used += item[1]
        total_profit += item[2]
    return mask, total_profit, used


def exact_optimum(values: Sequence[int] | None) -> int:
    parsed = _parse(values, False, len(values) if isinstance(values, (list, tuple)) else None)
    if parsed is None:
        return -1
    capacity, items = parsed
    best = 0
    for mask in range(1 << len(items)):
        weight = sum(item[1] for item in items if mask & (1 << item[0]))
        if weight <= capacity:
            best = max(best, sum(item[2] for item in items if mask & (1 << item[0])))
    return best


def expected_result(values: Sequence[int] | None, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    parsed = _parse(values, input_is_null, input_length)
    if parsed is None:
        return -1
    capacity, items = parsed
    prefix, lower_bound, exact = _lower_bound(capacity, items)
    if exact:
        mask = sum(1 << item[0] for item in prefix)
        profit = sum(item[2] for item in prefix)
        return (profit << 8) | mask

    small = [item for item in items if 4 * item[2] <= lower_bound]
    groups: dict[int, list[tuple[int, int, int]]] = {}
    for item in items:
        if 4 * item[2] > lower_bound:
            q = _q(item[2], lower_bound)
            if q <= 0:
                return -1
            groups.setdefault(q, []).append(item)
    grouped = []
    for q in sorted(groups, reverse=True):
        ordered = sorted(groups[q], key=lambda item: (item[1], item[0]))
        grouped.append((q, ordered[:min(len(ordered), MAX_SCALED_PROFIT // q)]))

    best_score = -1
    best_profit = -1
    best_weight = MAX_CAPACITY + 1
    best_mask = 0

    def enumerate_groups(position: int, scaled_total: int, large_weight: int,
                         large_mask: int, large_profit: int) -> None:
        nonlocal best_score, best_profit, best_weight, best_mask
        if position == len(grouped):
            small_mask, small_profit, small_weight = _small_prefix(
                capacity - large_weight, small
            )
            score = lower_bound * scaled_total + 16 * small_profit
            total_profit = large_profit + small_profit
            total_weight = large_weight + small_weight
            mask = large_mask | small_mask
            if (score > best_score or score == best_score
                    and (total_profit > best_profit
                         or total_profit == best_profit
                         and (total_weight < best_weight
                              or total_weight == best_weight and mask < best_mask))):
                best_score = score
                best_profit = total_profit
                best_weight = total_weight
                best_mask = mask
            return

        q, group = grouped[position]
        group_weight = 0
        group_mask = 0
        group_profit = 0
        for take in range(len(group) + 1):
            if large_weight + group_weight <= capacity:
                enumerate_groups(position + 1, scaled_total + take * q,
                                 large_weight + group_weight,
                                 large_mask | group_mask,
                                 large_profit + group_profit)
            if take == len(group):
                break
            item = group[take]
            group_weight += item[1]
            group_mask |= 1 << item[0]
            group_profit += item[2]

    enumerate_groups(0, 0, 0, 0, 0)
    return (best_profit << 8) | best_mask
