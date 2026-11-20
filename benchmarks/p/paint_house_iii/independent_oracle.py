"""Exhaustive color assignment oracle, independent of the primary DP."""

from __future__ import annotations

from collections.abc import Sequence
from itertools import product

from .primary_oracle import (
    I64_MAX,
    I64_MIN,
    MAX_COLORS,
    MAX_HOUSES,
    MAX_PARSEABLE_INPUT_LENGTH,
)


def _decode(
    values: Sequence[int] | None,
    input_is_null: bool,
    input_length: int | None,
) -> tuple[int, int, int, list[int], list[int]] | None:
    if (
        type(input_is_null) is not bool
        or input_is_null
        or not isinstance(values, (list, tuple))
        or not 3 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
        or any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values)
    ):
        return None
    if input_length is not None and (
        type(input_length) is not int or input_length != len(values)
    ):
        return None
    houses_count, colors, target = values[:3]
    if not 1 <= houses_count <= MAX_HOUSES or not 1 <= colors <= MAX_COLORS:
        return None
    if not 1 <= target <= houses_count or len(values) != 3 + houses_count + houses_count * colors:
        return None
    houses = list(values[3 : 3 + houses_count])
    costs = list(values[3 + houses_count :])
    if any(not 0 <= house <= colors for house in houses):
        return None
    if any(not 0 <= cost <= 100 for cost in costs):
        return None
    return houses_count, colors, target, houses, costs


def expected_output(
    values: Sequence[int] | None,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> int:
    decoded = _decode(values, input_is_null, input_length)
    if decoded is None:
        return -1
    houses_count, colors, target, houses, costs = decoded
    unpainted = [index for index, color in enumerate(houses) if color == 0]
    best = None
    for assignments in product(range(1, colors + 1), repeat=len(unpainted)):
        final_colors = houses.copy()
        total_cost = 0
        for index, color in zip(unpainted, assignments):
            final_colors[index] = color
            total_cost += costs[index * colors + color - 1]
        groups = 1
        for index in range(1, houses_count):
            if final_colors[index] != final_colors[index - 1]:
                groups += 1
        if groups == target and (best is None or total_cost < best):
            best = total_cost
    return -1 if best is None else best
