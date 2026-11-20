"""Rolling color/neighborhood dynamic program for bounded Paint House III."""

from __future__ import annotations

from collections.abc import Sequence

MAX_HOUSES = 8
MAX_COLORS = 4
MAX_VALID_INPUT_LENGTH = 43
MAX_PARSEABLE_INPUT_LENGTH = 44
MAX_INPUT_LENGTH = MAX_PARSEABLE_INPUT_LENGTH
MAX_RESULT = 800
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1
OFFICIAL_SOURCE_URL = "https://leetcode.com/problems/paint-house-iii/"


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
    infinity = MAX_RESULT + 1
    previous = [[infinity] * (target + 1) for _ in range(colors + 1)]

    for color in range(1, colors + 1):
        if houses[0] == 0 or houses[0] == color:
            paint_cost = costs[color - 1] if houses[0] == 0 else 0
            previous[color][1] = paint_cost

    for index in range(1, houses_count):
        current = [[infinity] * (target + 1) for _ in range(colors + 1)]
        for color in range(1, colors + 1):
            if houses[index] != 0 and houses[index] != color:
                continue
            paint_cost = costs[index * colors + color - 1] if houses[index] == 0 else 0
            for groups in range(1, target + 1):
                best = infinity
                for old_color in range(1, colors + 1):
                    old_groups = groups - int(old_color != color)
                    if old_groups >= 1 and previous[old_color][old_groups] < best:
                        best = previous[old_color][old_groups]
                if best < infinity:
                    current[color][groups] = best + paint_cost
        previous = current

    answer = min(previous[color][target] for color in range(1, colors + 1))
    return -1 if answer >= infinity else answer
