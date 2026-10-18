"""Oracle for the deterministic R two-state Kalman filter source variant."""

from __future__ import annotations

import math
from collections.abc import Sequence

MIN_OBSERVATIONS = 1
MAX_OBSERVATIONS = 12
MAX_PARSEABLE_INPUT_LENGTH = 64
MAX_OUTPUT_ELEMENTS = 30
MIN_OBSERVATION = -1000.0
MAX_OBSERVATION = 1000.0
INVALID_RESULT = -1
INVALID_OUTPUT_RESULT = -2


def _matmul(left: list[list[float]], right: list[list[float]]) -> list[list[float]]:
    rows = len(left)
    columns = len(right[0])
    inner = len(right)
    return [
        [sum(left[i][k] * right[k][j] for k in range(inner)) for j in range(columns)]
        for i in range(rows)
    ]


def _decode(values: object) -> list[float] | None:
    if (
        not isinstance(values, (list, tuple))
        or not MIN_OBSERVATIONS <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
        or len(values) > MAX_OBSERVATIONS
        or any(type(value) not in (int, float) for value in values)
    ):
        return None
    try:
        observations = [float(value) for value in values]
    except (OverflowError, ValueError):
        return None
    if any(
        not math.isfinite(value) or not MIN_OBSERVATION <= value <= MAX_OBSERVATION
        for value in observations
    ):
        return None
    return observations


def expected_result(values: Sequence[int | float]) -> list[float] | None:
    """Return flattened filtered states and final prediction artifacts, or None."""
    observations = _decode(values)
    if observations is None:
        return None

    transition = [[1.0, 0.0], [1.0, 1.0]]
    transition_t = [[1.0, 1.0], [0.0, 1.0]]
    observation = [[1.0, 0.0]]
    observation_t = [[1.0], [0.0]]
    process_noise = [[0.0001, 0.0], [0.0, 0.0001]]
    identity = [[1.0, 0.0], [0.0, 1.0]]
    ones = [[1.0, 1.0], [1.0, 1.0]]
    state = [observations[0], 0.0]
    covariance = [row[:] for row in identity]
    filtered_states: list[float] = []
    state_pred = [0.0, 0.0]
    covariance_pred = [row[:] for row in identity]

    for measured in observations:
        state_pred = [
            sum(transition[i][j] * state[j] for j in range(2))
            for i in range(2)
        ]
        covariance_pred = _matmul(_matmul(transition, covariance), transition_t)
        covariance_pred = [
            [covariance_pred[i][j] + process_noise[i][j] for j in range(2)]
            for i in range(2)
        ]

        innovation = _matmul(_matmul(observation, covariance_pred), observation_t)[0][0] + 0.1
        gain = _matmul(_matmul(covariance_pred, observation_t), [[1.0 / innovation]])
        residual = measured - _matmul(observation, [[state_pred[0]], [state_pred[1]]])[0][0]
        state = [state_pred[i] + gain[i][0] * residual for i in range(2)]
        filtered_states.extend(state)

        gain_observation = _matmul(gain, observation)
        update_matrix = [
            [ones[i][j] - gain_observation[i][j] for j in range(2)]
            for i in range(2)
        ]
        covariance = _matmul(update_matrix, covariance_pred)

    # R stores matrices column-major; preserve that order for P_pred's scalar encoding.
    covariance_pred_column_major = [
        covariance_pred[0][0], covariance_pred[1][0],
        covariance_pred[0][1], covariance_pred[1][1],
    ]
    return filtered_states + state_pred + covariance_pred_column_major


def expected_output(
    values: Sequence[int | float],
    output_capacity: int = MAX_OUTPUT_ELEMENTS,
    output_is_null: bool = False,
) -> tuple[int, list[float]]:
    expected = expected_result(values)
    if expected is None:
        return INVALID_RESULT, []
    if type(output_is_null) is not bool or type(output_capacity) is not int or output_capacity < 0:
        return INVALID_RESULT, []
    if output_is_null or output_capacity < len(expected):
        return INVALID_OUTPUT_RESULT, []
    return len(expected), expected
