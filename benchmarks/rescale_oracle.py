"""Oracle for the pinned Lua discrete random range rescaler."""

from __future__ import annotations

MAX_RANDOM_RANGE = 64
MAX_NEW_RANGE = 256
MAX_DRAWS = 256
MAX_INPUT_LENGTH = 3 + MAX_DRAWS + 1  # admit one over-bound draw count
INVALID_RESULT = -1


def expected_result(values: list[int]) -> int:
    if (not isinstance(values, list) or len(values) < 3 or len(values) > MAX_INPUT_LENGTH
            or any(type(value) is not int or not -(2**63) <= value <= 2**63 - 1
                   for value in values)):
        return INVALID_RESULT

    max_value, new_max, draw_count = values[:3]
    if (not 2 <= max_value <= MAX_RANDOM_RANGE
            or not 1 <= new_max <= MAX_NEW_RANGE
            or not 1 <= draw_count <= MAX_DRAWS
            or len(values) != 3 + draw_count):
        return INVALID_RESULT

    draws = values[3:]
    if any(not 0 <= draw < max_value for draw in draws):
        return INVALID_RESULT

    cursor = 0

    def next_draw() -> int:
        nonlocal cursor
        if cursor >= len(draws):
            raise IndexError("draw stream exhausted")
        draw = draws[cursor]
        cursor += 1
        return draw

    try:
        if new_max == max_value:
            return next_draw()

        if new_max < max_value:
            threshold = max_value - max_value % new_max
            while True:
                draw = next_draw()
                if draw < threshold:
                    return draw % new_max

        def upscaled_draw() -> tuple[int, int]:
            result = 0
            power = 1
            while power < new_max:
                result += power * next_draw()
                power *= max_value
            return result, power

        first_result, first_power = upscaled_draw()
        if first_power == new_max:
            return first_result

        threshold = first_power - first_power % new_max
        result = first_result
        while result >= threshold:
            result, _ = upscaled_draw()
        return result % new_max
    except IndexError:
        return INVALID_RESULT
