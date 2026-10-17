"""Oracle for one bounded RMSprop parameter-and-state update."""

from __future__ import annotations

from collections.abc import Sequence
import math

MIN_VECTOR_LENGTH = 0
MAX_VECTOR_LENGTH = 32
MIN_PARAMETER = -100.0
MAX_PARAMETER = 100.0
MIN_GRADIENT = -100.0
MAX_GRADIENT = 100.0
MIN_LEARNING_RATE = 1e-6
MAX_LEARNING_RATE = 1.0
MIN_RHO = 0.0
MAX_RHO = 0.99
MIN_EPSILON = 1e-8
MAX_EPSILON = 1.0
MIN_MOVING_AVERAGE = 0.0
MAX_MOVING_AVERAGE = 10_000.0
MAX_VALID_INPUT_LENGTH = 5 + 3 * MAX_VECTOR_LENGTH
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_OUTPUT_ELEMENTS = 2 * MAX_VECTOR_LENGTH
INVALID_RESULT = -1
OUTPUT_ERROR = -2
ABSOLUTE_TOLERANCE = 1e-12
RELATIVE_TOLERANCE = 1e-12


def _finite_number(value: object) -> bool:
    if type(value) not in (int, float):
        return False
    try:
        return math.isfinite(float(value))
    except OverflowError:
        return False


def _parse(
    values: Sequence[int | float] | None,
) -> tuple[int, int, float, float, float, list[float], list[float], list[float]] | None:
    if (
        not isinstance(values, (list, tuple))
        or not 5 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
        or any(not _finite_number(value) for value in values)
    ):
        return None

    count_value = float(values[0])
    state_mode_value = float(values[1])
    if not count_value.is_integer() or not state_mode_value.is_integer():
        return None
    count = int(count_value)
    state_mode = int(state_mode_value)
    if not MIN_VECTOR_LENGTH <= count <= MAX_VECTOR_LENGTH or state_mode not in (0, 1):
        return None

    expected_length = 5 + 2 * count + (count if state_mode == 1 else 0)
    if len(values) != expected_length:
        return None

    learning_rate, rho, epsilon = (float(value) for value in values[2:5])
    if not MIN_LEARNING_RATE <= learning_rate <= MAX_LEARNING_RATE:
        return None
    if not MIN_RHO <= rho <= MAX_RHO:
        return None
    if not MIN_EPSILON <= epsilon <= MAX_EPSILON:
        return None

    params = [float(value) for value in values[5 : 5 + count]]
    gradients = [float(value) for value in values[5 + count : 5 + 2 * count]]
    if any(not MIN_PARAMETER <= value <= MAX_PARAMETER for value in params):
        return None
    if any(not MIN_GRADIENT <= value <= MAX_GRADIENT for value in gradients):
        return None

    if state_mode == 0:
        moving_avg = [0.0] * count
    else:
        moving_avg = [float(value) for value in values[5 + 2 * count :]]
        if any(
            not MIN_MOVING_AVERAGE <= value <= MAX_MOVING_AVERAGE
            for value in moving_avg
        ):
            return None
    return count, state_mode, learning_rate, rho, epsilon, params, gradients, moving_avg


def _update(
    learning_rate: float,
    rho: float,
    epsilon: float,
    params: Sequence[float],
    gradients: Sequence[float],
    moving_avg: list[float],
) -> list[float]:
    updated_params: list[float] = []
    for index, (param, gradient) in enumerate(zip(params, gradients)):
        moving_avg[index] = rho * moving_avg[index] + (1 - rho) * gradient**2
        updated_params.append(
            param - (learning_rate / math.sqrt(moving_avg[index] + epsilon)) * gradient
        )
    return [*updated_params, *moving_avg]


def expected_result(values: Sequence[int | float] | None) -> list[float] | None:
    """Return updated parameters followed by the updated moving-average state."""
    parsed = _parse(values)
    if parsed is None:
        return None
    _, _, learning_rate, rho, epsilon, params, gradients, moving_avg = parsed
    output = _update(learning_rate, rho, epsilon, params, gradients, moving_avg)
    if len(output) > MAX_OUTPUT_ELEMENTS or any(not math.isfinite(value) for value in output):
        return None
    return output


def expected_output(
    values: Sequence[int | float] | None,
    output_capacity: int | None = None,
    output_is_null: bool = False,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> tuple[int, list[float]]:
    """Return status and updated parameter/state vectors for the slice ABI."""
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
    if input_is_null or not isinstance(values, (list, tuple)):
        return INVALID_RESULT, []
    if input_length is not None and input_length != len(values):
        return INVALID_RESULT, []

    output = expected_result(values)
    if output is None:
        return INVALID_RESULT, []
    if output_is_null or (
        output_capacity is not None and output_capacity < len(output)
    ):
        return OUTPUT_ERROR, []
    return len(output), output
