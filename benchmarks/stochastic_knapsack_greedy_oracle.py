"""Exact bounded oracle for the chapter's nonadaptive stochastic-knapsack rule."""

from __future__ import annotations

import itertools
import struct
from collections.abc import Sequence
from functools import cmp_to_key
from fractions import Fraction

MAX_ITEMS = 5
MAX_CAPACITY = 8
MAX_INPUT_LENGTH = 43
MAX_OUTPUT_BYTES = 72


def _parse(values: Sequence[int] | None):
    if (not isinstance(values, (list, tuple)) or not 2 <= len(values) <= MAX_INPUT_LENGTH
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return None
    n, capacity = values[0], values[1]
    if not 1 <= n <= MAX_ITEMS or not 1 <= capacity <= MAX_CAPACITY:
        return None
    position = 2
    items = []
    for _ in range(n):
        if position + 2 > len(values):
            return None
        reward, atom_count = values[position:position + 2]
        position += 2
        if not 0 <= reward <= 20 or not 1 <= atom_count <= 3:
            return None
        distribution = []
        denominator = 0
        fit_weight = 0
        truncated_weighted_size = 0
        for _ in range(atom_count):
            if position + 2 > len(values):
                return None
            size, weight = values[position:position + 2]
            position += 2
            if not 0 <= size <= capacity + 1 or not 1 <= weight <= 3:
                return None
            distribution.append((size, weight))
            denominator += weight
            if size <= capacity:
                fit_weight += weight
            truncated_weighted_size += min(size, capacity) * weight
        if denominator > 9 or truncated_weighted_size == 0:
            return None
        items.append({"reward": reward, "distribution": distribution,
                      "denominator": denominator, "fit_weight": fit_weight,
                      "truncated_weighted_size": truncated_weighted_size})
    if position != len(values):
        return None
    return capacity, items


def _density_order(items):
    def compare(left, right):
        left_numerator = items[left]["reward"] * items[left]["fit_weight"]
        right_numerator = items[right]["reward"] * items[right]["fit_weight"]
        left_denominator = items[left]["truncated_weighted_size"]
        right_denominator = items[right]["truncated_weighted_size"]
        left_cross = left_numerator * right_denominator
        right_cross = right_numerator * left_denominator
        if left_cross != right_cross:
            return -1 if left_cross > right_cross else 1
        return (left > right) - (left < right)

    return sorted(range(len(items)), key=cmp_to_key(compare))


def _scenario_score(capacity, items, policy):
    score = 0
    distributions = [item["distribution"] for item in items]
    for selected_atoms in itertools.product(*(range(len(dist)) for dist in distributions)):
        scenario_weight = 1
        sizes = []
        for item_index, atom_index in enumerate(selected_atoms):
            size, weight = distributions[item_index][atom_index]
            scenario_weight *= weight
            sizes.append(size)
        used = 0
        reward = 0
        for item_index in policy:
            if used + sizes[item_index] > capacity:
                break
            used += sizes[item_index]
            reward += items[item_index]["reward"]
        score += scenario_weight * reward
    return score


def _payload(parsed) -> bytes:
    capacity, items = parsed
    single = max(range(len(items)), key=lambda index: (
        Fraction(items[index]["reward"] * items[index]["fit_weight"],
                 items[index]["denominator"]), -index))
    order = _density_order(items)
    denominator = 1
    for item in items:
        denominator *= item["denominator"]
    single_score = _scenario_score(capacity, items, [single])
    order_score = _scenario_score(capacity, items, order)
    if order_score > single_score:
        kind, selected, numerator = 1, order, order_score
    else:
        kind, selected, numerator = 0, [single], single_score
    words = [kind, len(selected), *selected, numerator, denominator]
    return struct.pack("<" + "q" * len(words), *words)


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or capacity is not None and (type(capacity) is not int or capacity < 0)
            or input_length is not None and (type(input_length) is not int
                                             or not 0 <= input_length <= MAX_INPUT_LENGTH)
            or input_is_null and values not in (None, [], ())
            or not input_is_null and values is not None and input_length is not None
            and input_length != len(values)):
        return -1, b""
    if input_is_null or values is None:
        return -1, b""
    parsed = _parse(values)
    if parsed is None:
        return -1, b""
    payload = _payload(parsed)
    if output_is_null or capacity is not None and capacity < len(payload):
        return -2, b""
    return len(payload), payload
