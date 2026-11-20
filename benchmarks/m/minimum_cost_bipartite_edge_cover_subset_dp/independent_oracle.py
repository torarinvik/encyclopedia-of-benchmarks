"""Minimum-weight-matching reduction reference for edge-cover costs."""

from __future__ import annotations

MAX_LEFT = 8
MAX_RIGHT = 8
MAX_COST = 1000
MAX_VALID_INPUT_LENGTH = 66
MAX_PARSEABLE_INPUT_LENGTH = 67
WORKSPACE_BYTES = 8192


def _valid(values: list[int] | tuple[int, ...] | None, input_is_null: bool,
           input_length: int | None) -> tuple[int, int] | None:
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple))
            or len(values) < 2 or len(values) > MAX_PARSEABLE_INPUT_LENGTH):
        return None
    if input_length is None:
        input_length = len(values)
    if type(input_length) is not int or input_length != len(values):
        return None
    if any(type(value) is not int or not -(1 << 63) <= value < (1 << 63) for value in values):
        return None
    left, right = values[:2]
    if not 1 <= left <= MAX_LEFT or not 1 <= right <= MAX_RIGHT:
        return None
    if len(values) != 2 + left * right or any(not 0 <= cost <= MAX_COST for cost in values[2:]):
        return None
    return left, right


def expected_result(values: list[int] | tuple[int, ...] | None,
                    input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    """Use cheapest incident edges plus maximum transformed-weight matching."""
    parsed = _valid(values, input_is_null, input_length)
    if parsed is None:
        return -1
    left_count, right_count = parsed
    assert values is not None
    matrix = [values[2 + i * right_count:2 + (i + 1) * right_count]
              for i in range(left_count)]
    left_minimum = [min(row) for row in matrix]
    right_minimum = [min(matrix[i][j] for i in range(left_count))
                     for j in range(right_count)]
    baseline = sum(left_minimum) + sum(right_minimum)

    # The matching pairs endpoints whose shared edge saves cost relative to
    # selecting each endpoint's cheapest incident edge independently.
    best_by_mask = [0] * (1 << right_count)
    for left in range(left_count):
        following = best_by_mask.copy()
        for mask, value in enumerate(best_by_mask):
            for right in range(right_count):
                bit = 1 << right
                gain = left_minimum[left] + right_minimum[right] - matrix[left][right]
                if mask & bit == 0 and gain > 0:
                    combined = mask | bit
                    candidate = value + gain
                    if candidate > following[combined]:
                        following[combined] = candidate
        best_by_mask = following
    return baseline - max(best_by_mask)
