"""Oracle for bounded MomentumSGD traces across independent parameter IDs."""

from __future__ import annotations

from collections.abc import Sequence
import math

MIN_GROUP_COUNT = 1
MAX_GROUP_COUNT = 8
MIN_VECTOR_LENGTH = 1
MAX_VECTOR_LENGTH = 16
MAX_GROUP_VECTOR_ELEMENTS = 32
MIN_CALL_COUNT = 1
MAX_CALL_COUNT = 8
MIN_PARAMETER = -1000.0
MAX_PARAMETER = 1000.0
MIN_GRADIENT = -1000.0
MAX_GRADIENT = 1000.0
MIN_LEARNING_RATE = 1e-6
MAX_LEARNING_RATE = 1.0
MIN_MOMENTUM = 0.0
MAX_MOMENTUM = 0.99
MAX_VALID_INPUT_LENGTH = 5 + MAX_CALL_COUNT * (1 + 2 * MAX_VECTOR_LENGTH)
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_OUTPUT_ELEMENTS = 2 * MAX_GROUP_VECTOR_ELEMENTS
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
) -> tuple[int, int, int, float, float, list[tuple[int, list[float], list[float]]]] | None:
    if (
        not isinstance(values, (list, tuple))
        or not 5 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
        or any(not _finite_number(value) for value in values)
    ):
        return None

    header = [float(value) for value in values[:3]]
    if any(not value.is_integer() for value in header):
        return None
    group_count, vector_length, call_count = (int(value) for value in header)
    if not MIN_GROUP_COUNT <= group_count <= MAX_GROUP_COUNT:
        return None
    if not MIN_VECTOR_LENGTH <= vector_length <= MAX_VECTOR_LENGTH:
        return None
    if group_count * vector_length > MAX_GROUP_VECTOR_ELEMENTS:
        return None
    if not MIN_CALL_COUNT <= call_count <= MAX_CALL_COUNT or call_count < group_count:
        return None

    expected_length = 5 + call_count * (1 + 2 * vector_length)
    if len(values) != expected_length:
        return None

    learning_rate = float(values[3])
    momentum = float(values[4])
    if not MIN_LEARNING_RATE <= learning_rate <= MAX_LEARNING_RATE:
        return None
    if not MIN_MOMENTUM <= momentum <= MAX_MOMENTUM:
        return None

    events: list[tuple[int, list[float], list[float]]] = []
    seen_ids: set[int] = set()
    cursor = 5
    for _ in range(call_count):
        id_value = float(values[cursor])
        if not id_value.is_integer():
            return None
        param_id = int(id_value)
        if not 0 <= param_id < group_count:
            return None
        seen_ids.add(param_id)
        cursor += 1

        params = [float(value) for value in values[cursor : cursor + vector_length]]
        cursor += vector_length
        gradients = [float(value) for value in values[cursor : cursor + vector_length]]
        cursor += vector_length
        if any(not MIN_PARAMETER <= value <= MAX_PARAMETER for value in params):
            return None
        if any(not MIN_GRADIENT <= value <= MAX_GRADIENT for value in gradients):
            return None
        events.append((param_id, params, gradients))

    if seen_ids != set(range(group_count)):
        return None
    return group_count, vector_length, call_count, learning_rate, momentum, events


def _update_trace(
    group_count: int,
    vector_length: int,
    learning_rate: float,
    momentum: float,
    events: Sequence[tuple[int, Sequence[float], Sequence[float]]],
) -> list[float]:
    velocity_by_id: dict[int, list[float]] = {}
    last_params_by_id: dict[int, list[float]] = {}
    for param_id, params, gradients in events:
        old_velocity = velocity_by_id.get(param_id)
        if old_velocity is None:
            old_velocity = [0.0] * vector_length
        updated_velocity = [
            momentum * velocity - learning_rate * gradient
            for velocity, gradient in zip(old_velocity, gradients)
        ]
        updated_params = [
            param + velocity for param, velocity in zip(params, updated_velocity)
        ]
        velocity_by_id[param_id] = updated_velocity
        last_params_by_id[param_id] = updated_params
    output: list[float] = []
    for param_id in range(group_count):
        output.extend(last_params_by_id[param_id])
    for param_id in range(group_count):
        output.extend(velocity_by_id[param_id])
    return output


def expected_result(values: Sequence[int | float] | None) -> list[float] | None:
    """Return last parameters then retained velocity, in parameter-ID order."""
    parsed = _parse(values)
    if parsed is None:
        return None
    group_count, vector_length, _, learning_rate, momentum, events = parsed
    output = _update_trace(group_count, vector_length, learning_rate, momentum, events)
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
    """Return status and final per-ID parameters/velocities for the slice ABI."""
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
    if output_is_null or (output_capacity is not None and output_capacity < len(output)):
        return OUTPUT_ERROR, []
    return len(output), output
