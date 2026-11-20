"""Bounded Lawler dyadic-scaling FPTAS for 0-1 knapsack."""

from __future__ import annotations

from collections.abc import Sequence
from functools import cmp_to_key

MIN_ITEMS = 4
MAX_ITEMS = 8
MIN_CAPACITY = 1
MAX_CAPACITY = 30
MIN_PROFIT = 32
MAX_PROFIT = 200
MAX_INPUT_LENGTH = 19
MAX_VALID_INPUT_LENGTH = 18
MAX_PARSEABLE_INPUT_LENGTH = 19
EPSILON_DENOMINATOR = 2
MAX_SCALED_PROFIT = 32
MAX_MASK = (1 << MAX_ITEMS) - 1
MAX_RESULT = (MAX_ITEMS * MAX_PROFIT << 8) | MAX_MASK


def _parse(values: Sequence[int] | None, input_is_null: bool = False,
           input_length: int | None = None) -> tuple[int, list[tuple[int, int, int]]] | None:
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple))
            or not 2 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)
            or input_length is not None
            and (type(input_length) is not int or input_length != len(values))):
        return None
    capacity, count = values[0], values[1]
    if (not MIN_CAPACITY <= capacity <= MAX_CAPACITY
            or not MIN_ITEMS <= count <= MAX_ITEMS
            or len(values) != 2 + 2 * count):
        return None
    items: list[tuple[int, int, int]] = []
    for item_id in range(count):
        weight, profit = values[2 + 2 * item_id:4 + 2 * item_id]
        if not 1 <= weight <= capacity or not MIN_PROFIT <= profit <= MAX_PROFIT:
            return None
        items.append((item_id, weight, profit))
    return capacity, items


def _ratio_compare(left: tuple[int, int, int], right: tuple[int, int, int]) -> int:
    left_product = left[2] * right[1]
    right_product = right[2] * left[1]
    if left_product != right_product:
        return -1 if left_product > right_product else 1
    return (left[0] > right[0]) - (left[0] < right[0])


def _pack(mask: int, profit: int) -> int:
    return (profit << 8) | mask


def _ratio_prefix(capacity: int, items: Sequence[tuple[int, int, int]]) -> tuple[list, int, bool]:
    ordered = sorted(items, key=cmp_to_key(_ratio_compare))
    prefix: list[tuple[int, int, int]] = []
    used = 0
    profit = 0
    for position, item in enumerate(ordered):
        if used + item[1] > capacity:
            return prefix, max(profit, max(candidate[2] for candidate in items)), False
        prefix.append(item)
        used += item[1]
        profit += item[2]
        if used == capacity:
            return prefix, profit, True
        if position + 1 == len(ordered):
            return prefix, profit, True
    return prefix, profit, True


def _scaled_profit(profit: int, lower_bound: int) -> int:
    # T=P0/4 and K=P0/16. The interval test is written without fractions:
    # 2^k P0 < 4p <= 2^(k+1)P0.
    for exponent in range(2):
        scale = 1 << exponent
        if scale * lower_bound < 4 * profit <= (scale << 1) * lower_bound:
            return scale * (16 * profit // (scale * lower_bound))
    return -1


def _prune(states: list[tuple[int, int, int, int]]) -> list[tuple[int, int, int, int]]:
    # State fields are scaled profit, weight, large-item mask, and true profit.
    by_profit: dict[int, tuple[int, int, int, int]] = {}
    for state in states:
        scaled, weight, mask, true_profit = state
        current = by_profit.get(scaled)
        if (current is None or weight < current[1]
                or weight == current[1]
                and (true_profit > current[3]
                     or true_profit == current[3] and mask < current[2])):
            by_profit[scaled] = state
    kept: list[tuple[int, int, int, int]] = []
    best_weight = MAX_CAPACITY + 1
    for scaled in sorted(by_profit, reverse=True):
        state = by_profit[scaled]
        if state[1] < best_weight:
            kept.append(state)
            best_weight = state[1]
    return kept


def _small_fill(capacity: int, small: Sequence[tuple[int, int, int]]) -> tuple[int, int, int]:
    mask = 0
    profit = 0
    used = 0
    for item_id, weight, item_profit in sorted(small, key=cmp_to_key(_ratio_compare)):
        if used + weight > capacity:
            break
        used += weight
        profit += item_profit
        mask |= 1 << item_id
    return mask, profit, used


def expected_result(values: Sequence[int] | None, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    parsed = _parse(values, input_is_null, input_length)
    if parsed is None:
        return -1
    capacity, items = parsed
    ratio_prefix, lower_bound, exact = _ratio_prefix(capacity, items)
    if exact:
        mask = sum(1 << item[0] for item in ratio_prefix)
        profit = sum(item[2] for item in ratio_prefix)
        return _pack(mask, profit)

    small: list[tuple[int, int, int]] = []
    groups: dict[int, list[tuple[int, int, int]]] = {}
    for item in items:
        if 4 * item[2] <= lower_bound:
            small.append(item)
        else:
            scaled = _scaled_profit(item[2], lower_bound)
            if scaled <= 0:
                return -1
            groups.setdefault(scaled, []).append(item)

    # For epsilon=1/2, P* <= 2P0 and K=P0/16, so q-groups need
    # only the floor(32/q) lightest members.
    choices: list[tuple[int, list[tuple[int, int, int]]]] = []
    for scaled in sorted(groups, reverse=True):
        ordered = sorted(groups[scaled], key=lambda item: (item[1], item[0]))
        choices.append((scaled, ordered[:min(len(ordered), MAX_SCALED_PROFIT // scaled)]))

    states = [(0, 0, 0, 0)]
    for scaled, group in choices:
        candidates: list[tuple[int, int, int, int]] = []
        for old_scaled, old_weight, old_mask, old_profit in states:
            group_weight = 0
            group_mask = 0
            group_profit = 0
            candidates.append((old_scaled, old_weight, old_mask, old_profit))
            for item in group:
                group_weight += item[1]
                if old_weight + group_weight > capacity:
                    break
                group_mask |= 1 << item[0]
                group_profit += item[2]
                candidates.append((old_scaled + scaled * (group_mask.bit_count()),
                                   old_weight + group_weight,
                                   old_mask | group_mask,
                                   old_profit + group_profit))
        states = _prune(candidates)

    best_score = -1
    best_profit = -1
    best_weight = MAX_CAPACITY + 1
    best_mask = 0
    for scaled, large_weight, large_mask, large_profit in states:
        small_mask, small_profit, small_weight = _small_fill(
            capacity - large_weight, small
        )
        score = lower_bound * scaled + 16 * small_profit
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
    result = _pack(best_mask, best_profit)
    return result if result <= MAX_RESULT else -1
