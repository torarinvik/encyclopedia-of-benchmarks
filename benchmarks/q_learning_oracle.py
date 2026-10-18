"""Oracle for the deterministic update step of the pinned Q-learning source."""

from __future__ import annotations

import math
from collections.abc import Sequence

MIN_NEXT_ACTIONS = 0
MAX_NEXT_ACTIONS = 4
MIN_SCALAR = -100.0
MAX_SCALAR = 100.0
MIN_RATE = 0.0
MAX_RATE = 1.0
MAX_VALID_INPUT_LENGTH = 6 + MAX_NEXT_ACTIONS
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_OUTPUT_ELEMENTS = 1
ABSOLUTE_TOLERANCE = 1e-12
RELATIVE_TOLERANCE = 1e-12
INVALID_RESULT = -1
OUTPUT_ERROR = -2


def _finite_number(value: int | float) -> float | None:
    if type(value) not in (int, float):
        return None
    try:
        number = float(value)
    except OverflowError:
        return None
    return number if math.isfinite(number) else None


def _exact_integer(value: int | float) -> int | None:
    number = _finite_number(value)
    if number is None or not number.is_integer():
        return None
    return int(number)


def _decode_input(values: Sequence[float] | None):
    if (not isinstance(values, (list, tuple))
            or len(values) > MAX_PARSEABLE_INPUT_LENGTH):
        return None
    if len(values) < 6:
        return None

    done = _exact_integer(values[0])
    alpha = _finite_number(values[1])
    gamma = _finite_number(values[2])
    reward = _finite_number(values[3])
    old_q = _finite_number(values[4])
    next_count = _exact_integer(values[5])
    if (done not in (0, 1) or alpha is None or not MIN_RATE <= alpha <= MAX_RATE
            or gamma is None or not MIN_RATE <= gamma <= MAX_RATE
            or reward is None or not MIN_SCALAR <= reward <= MAX_SCALAR
            or old_q is None or not MIN_SCALAR <= old_q <= MAX_SCALAR
            or next_count is None
            or not MIN_NEXT_ACTIONS <= next_count <= MAX_NEXT_ACTIONS
            or len(values) != 6 + next_count):
        return None
    next_q_values = [_finite_number(value) for value in values[6:]]
    if any(value is None or not MIN_SCALAR <= value <= MAX_SCALAR
           for value in next_q_values):
        return None
    return bool(done), alpha, gamma, reward, old_q, next_q_values


def expected_output(
    values: Sequence[float] | None,
    output_capacity: int | None = None,
    output_is_null: bool = False,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> tuple[int, list[float]]:
    """Return the updated Q value or the documented ABI error."""
    if type(output_is_null) is not bool or type(input_is_null) is not bool:
        return INVALID_RESULT, []
    if output_capacity is not None and (
        type(output_capacity) is not int or output_capacity < 0
    ):
        return INVALID_RESULT, []
    if input_length is not None and (
        type(input_length) is not int or input_length < 0
    ):
        return INVALID_RESULT, []
    if input_is_null or values is None or not isinstance(values, (list, tuple)):
        return INVALID_RESULT, []
    if input_length is not None and input_length != len(values):
        return INVALID_RESULT, []

    decoded = _decode_input(values)
    if decoded is None:
        return INVALID_RESULT, []
    done, alpha, gamma, reward, old_q, next_q_values = decoded
    max_q_next = 0.0 if done or not next_q_values else max(next_q_values)
    updated = (1.0 - alpha) * old_q + alpha * (reward + gamma * max_q_next)
    if not math.isfinite(updated):
        return INVALID_RESULT, []
    if output_is_null or (
        output_capacity is not None and output_capacity < MAX_OUTPUT_ELEMENTS
    ):
        return OUTPUT_ERROR, []
    return MAX_OUTPUT_ELEMENTS, [updated]
