"""Oracle for the bounded source-faithful CTC loss workload."""

from __future__ import annotations

import math

MIN_TIME = 1
MAX_TIME = 32
MIN_CLASSES = 2
MAX_CLASSES = 16
MIN_TARGET = 1
MAX_TARGET = 16
PROBABILITY_SCALE = 1_000_000
MAX_INPUT_LENGTH = 3 + MAX_TARGET + MAX_TIME * MAX_CLASSES
INVALID_RESULT = -1e300
NEGATIVE_INFINITY = float("-inf")
I64_MIN = -(2**63)
I64_MAX = 2**63 - 1


def _logaddexp(left: float, right: float) -> float:
    if left == NEGATIVE_INFINITY:
        return right
    if right == NEGATIVE_INFINITY:
        return left
    larger = max(left, right)
    smaller = min(left, right)
    return larger + math.log1p(math.exp(smaller - larger))


def expected_result(values: list[int]) -> float:
    if (
        not isinstance(values, list)
        or len(values) < 3
        or len(values) > MAX_INPUT_LENGTH
        or any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values)
    ):
        return INVALID_RESULT

    time, classes, target_length = values[:3]
    if not MIN_TIME <= time <= MAX_TIME:
        return INVALID_RESULT
    if not MIN_CLASSES <= classes <= MAX_CLASSES:
        return INVALID_RESULT
    if not MIN_TARGET <= target_length <= MAX_TARGET:
        return INVALID_RESULT
    if len(values) != 3 + target_length + time * classes:
        return INVALID_RESULT

    targets = values[3 : 3 + target_length]
    if any(not 1 <= target < classes for target in targets):
        return INVALID_RESULT
    adjacent_repeats = sum(
        targets[index] == targets[index - 1] for index in range(1, target_length)
    )
    if time < target_length + adjacent_repeats:
        return INVALID_RESULT

    probabilities = values[3 + target_length :]
    for step in range(time):
        start = step * classes
        row = probabilities[start : start + classes]
        if any(not 1 <= probability <= PROBABILITY_SCALE for probability in row):
            return INVALID_RESULT
        if sum(row) != PROBABILITY_SCALE:
            return INVALID_RESULT

    extended_targets = [0] * (2 * target_length + 1)
    extended_targets[1::2] = targets
    states = len(extended_targets)
    alpha = [[NEGATIVE_INFINITY] * states for _ in range(time)]
    first_row = probabilities[:classes]
    alpha[0][0] = math.log(first_row[0] / PROBABILITY_SCALE)
    alpha[0][1] = math.log(first_row[extended_targets[1]] / PROBABILITY_SCALE)

    for step in range(1, time):
        row_start = step * classes
        for state, current_label in enumerate(extended_targets):
            value = alpha[step - 1][state]
            if state > 0:
                value = _logaddexp(value, alpha[step - 1][state - 1])
            if state > 1 and current_label != extended_targets[state - 2]:
                value = _logaddexp(value, alpha[step - 1][state - 2])
            probability = probabilities[row_start + current_label] / PROBABILITY_SCALE
            alpha[step][state] = value + math.log(probability)

    return -_logaddexp(alpha[-1][-1], alpha[-1][-2])
