"""Oracle for deterministic bounded replay of Python simulated annealing."""
from __future__ import annotations

import math
from collections.abc import Sequence

INVALID_RESULT = -1
SCALE = 1_000_000
MIN_COORDINATE = -16
MAX_COORDINATE = 16
MIN_STEP = 1
MAX_STEP = 4
MIN_START_TEMP = 1_000_000
MAX_START_TEMP = 10_000_000
MIN_RATE = 100_000
MAX_RATE = 500_000
MIN_THRESHOLD = 1_000_000
MAX_THRESHOLD = 9_999_999
ACCEPTANCE_LEVELS = frozenset((0, 999_999))
MAX_OUTER_ITERATIONS = 22
MAX_RANDOM_DRAWS = 176
MAX_VALID_INPUT_LENGTH = 365
MAX_PARSEABLE_INPUT_LENGTH = 366
STATE_CODE_WIDTH = 33
STATE_OFFSET = 16


def _score(x: int, y: int) -> int:
    return x * x + y * y


def _neighbors(x: int, y: int, step: int) -> list[tuple[int, int]]:
    return [
        (x - step, y - step),
        (x - step, y),
        (x - step, y + step),
        (x, y - step),
        (x, y + step),
        (x + step, y - step),
        (x + step, y),
        (x + step, y + step),
    ]


def expected_result(values: Sequence[int] | None) -> int:
    if (not isinstance(values, (list, tuple))
            or not 13 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
            or any(type(value) is not int or not -(2**63) <= value < 2**63
                   for value in values)):
        return INVALID_RESULT

    (x0, y0, step, min_x, max_x, min_y, max_y, find_max,
     start_temp_raw, rate_raw, threshold_raw, selection_count) = values[:12]
    if (not MIN_COORDINATE <= x0 <= MAX_COORDINATE
            or not MIN_COORDINATE <= y0 <= MAX_COORDINATE
            or not MIN_STEP <= step <= MAX_STEP
            or not MIN_COORDINATE <= min_x <= max_x <= MAX_COORDINATE
            or not MIN_COORDINATE <= min_y <= max_y <= MAX_COORDINATE
            or not min_x <= x0 <= max_x
            or not min_y <= y0 <= max_y
            or find_max not in (0, 1)
            or not MIN_START_TEMP <= start_temp_raw <= MAX_START_TEMP
            or not MIN_RATE <= rate_raw <= MAX_RATE
            or not MIN_THRESHOLD <= threshold_raw <= MAX_THRESHOLD
            or threshold_raw >= start_temp_raw
            or not 0 <= selection_count <= MAX_RANDOM_DRAWS):
        return INVALID_RESULT

    if selection_count > len(values) - 13:
        return INVALID_RESULT
    selection_start = 12
    selection_end = selection_start + selection_count
    acceptance_count_index = selection_end
    if acceptance_count_index >= len(values):
        return INVALID_RESULT
    acceptance_count = values[acceptance_count_index]
    if (not 0 <= acceptance_count <= MAX_RANDOM_DRAWS
            or len(values) != 13 + selection_count + acceptance_count):
        return INVALID_RESULT
    selections = values[selection_start:selection_end]
    acceptance_start = acceptance_count_index + 1
    acceptance_draws = values[acceptance_start:]
    if (any(not 0 <= index <= 7 for index in selections)
            or any(draw not in ACCEPTANCE_LEVELS for draw in acceptance_draws)):
        return INVALID_RESULT

    start_temp = start_temp_raw / SCALE
    rate = rate_raw / SCALE
    threshold = threshold_raw / SCALE
    current = (x0, y0)
    best: tuple[int, int] | None = None
    best_score: int | None = None
    selection_cursor = 0
    acceptance_cursor = 0
    current_temp = start_temp

    for _ in range(MAX_OUTER_ITERATIONS):
        current_score = _score(*current)
        if best is None or current_score > best_score:
            best = current
            best_score = current_score

        remaining = _neighbors(*current, step)
        next_state: tuple[int, int] | None = None
        while next_state is None and remaining:
            if selection_cursor >= len(selections):
                return INVALID_RESULT
            index = selections[selection_cursor]
            selection_cursor += 1
            if index >= len(remaining):
                return INVALID_RESULT
            candidate = remaining.pop(index)
            change = _score(*candidate) - current_score
            candidate_x, candidate_y = candidate
            if (candidate_x > max_x or candidate_x < min_x
                    or candidate_y > max_y or candidate_y < min_y):
                continue
            if not find_max:
                change = change * -1
            if change > 0:
                next_state = candidate
            else:
                if acceptance_cursor >= len(acceptance_draws):
                    return INVALID_RESULT
                draw = acceptance_draws[acceptance_cursor] / SCALE
                acceptance_cursor += 1
                probability = math.e ** (change / current_temp)
                if draw < probability:
                    next_state = candidate

        current_temp = current_temp - (current_temp * rate)
        if current_temp < threshold or next_state is None:
            break
        current = next_state
    else:
        return INVALID_RESULT

    if best is None:
        return INVALID_RESULT
    return (best[0] + STATE_OFFSET) * STATE_CODE_WIDTH + (best[1] + STATE_OFFSET)
