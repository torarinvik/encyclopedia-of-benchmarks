"""Independent bounded oracle for TheAlgorithms/Python's Muon optimizer."""

from __future__ import annotations

from collections.abc import Sequence
import math

MIN_GROUP_COUNT = 1
MAX_GROUP_COUNT = 4
MIN_ROWS = 1
MAX_ROWS = 4
MIN_COLUMNS = 1
MAX_COLUMNS = 4
MAX_MATRIX_ELEMENTS = 16
MAX_GROUP_MATRIX_ELEMENTS = 32
MIN_CALL_COUNT = 1
MAX_CALL_COUNT = 8
MIN_NS_STEPS = 0
MAX_NS_STEPS = 5
MIN_PARAMETER = -10.0
MAX_PARAMETER = 10.0
MIN_GRADIENT = -0.01
MAX_GRADIENT = 0.01
MIN_LEARNING_RATE = 0.0
MAX_LEARNING_RATE = 0.25
MIN_MOMENTUM = 0.0
MAX_MOMENTUM = 0.99
MAX_VALID_INPUT_LENGTH = 7 + MAX_CALL_COUNT * (1 + 2 * MAX_MATRIX_ELEMENTS)
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_OUTPUT_ELEMENTS = 2 * MAX_GROUP_MATRIX_ELEMENTS
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


def _integer(value: object) -> int | None:
    if not _finite_number(value):
        return None
    numeric = float(value)
    if not numeric.is_integer():
        return None
    return int(numeric)


def _transpose(matrix: list[list[float]]) -> list[list[float]]:
    return [list(column) for column in zip(*matrix)]


def _orthogonalize(
    flat_matrix: Sequence[float], rows: int, columns: int, ns_steps: int
) -> list[float]:
    matrix = [
        [float(flat_matrix[row * columns + column]) for column in range(columns)]
        for row in range(rows)
    ]
    transposed = rows < columns
    if transposed:
        matrix = _transpose(matrix)

    # Keep the source's raw, unnormalized Newton-Schulz recurrence and operation
    # order.  The small dimensions make this scalar implementation independent
    # of NumPy and avoid relying on a second matrix-library implementation.
    for _ in range(ns_steps):
        working_rows = len(matrix)
        working_columns = len(matrix[0])
        gram = [
            [
                sum(matrix[row][left] * matrix[row][right] for row in range(working_rows))
                for right in range(working_columns)
            ]
            for left in range(working_columns)
        ]
        product = [
            [
                sum(matrix[row][inner] * gram[inner][column]
                    for inner in range(working_columns))
                for column in range(working_columns)
            ]
            for row in range(working_rows)
        ]
        matrix = [
            [1.5 * matrix[row][column] - 0.5 * product[row][column]
             for column in range(working_columns)]
            for row in range(working_rows)
        ]

    if transposed:
        matrix = _transpose(matrix)
    return [value for row in matrix for value in row]


def _parse(
    values: Sequence[int | float] | None,
) -> tuple[
    int,
    int,
    int,
    int,
    float,
    float,
    list[tuple[int, list[float], list[float]]],
] | None:
    if (
        not isinstance(values, (list, tuple))
        or not 7 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
        or any(not _finite_number(value) for value in values)
    ):
        return None

    group_count = _integer(values[0])
    rows = _integer(values[1])
    columns = _integer(values[2])
    call_count = _integer(values[3])
    ns_steps = _integer(values[4])
    if None in (group_count, rows, columns, call_count, ns_steps):
        return None
    assert group_count is not None
    assert rows is not None
    assert columns is not None
    assert call_count is not None
    assert ns_steps is not None

    if not MIN_GROUP_COUNT <= group_count <= MAX_GROUP_COUNT:
        return None
    if not MIN_ROWS <= rows <= MAX_ROWS:
        return None
    if not MIN_COLUMNS <= columns <= MAX_COLUMNS:
        return None
    matrix_elements = rows * columns
    if matrix_elements > MAX_MATRIX_ELEMENTS:
        return None
    if group_count * matrix_elements > MAX_GROUP_MATRIX_ELEMENTS:
        return None
    if not MIN_CALL_COUNT <= call_count <= MAX_CALL_COUNT or call_count < group_count:
        return None
    if not MIN_NS_STEPS <= ns_steps <= MAX_NS_STEPS:
        return None

    expected_length = 7 + call_count * (1 + 2 * matrix_elements)
    if len(values) != expected_length:
        return None

    learning_rate = float(values[5])
    momentum = float(values[6])
    if not MIN_LEARNING_RATE <= learning_rate <= MAX_LEARNING_RATE:
        return None
    if not MIN_MOMENTUM <= momentum <= MAX_MOMENTUM:
        return None

    events: list[tuple[int, list[float], list[float]]] = []
    seen_ids: set[int] = set()
    cursor = 7
    for _ in range(call_count):
        param_id = _integer(values[cursor])
        if param_id is None or not 0 <= param_id < group_count:
            return None
        seen_ids.add(param_id)
        cursor += 1

        params = [float(value) for value in values[cursor : cursor + matrix_elements]]
        cursor += matrix_elements
        gradients = [float(value) for value in values[cursor : cursor + matrix_elements]]
        cursor += matrix_elements
        if any(not MIN_PARAMETER <= value <= MAX_PARAMETER for value in params):
            return None
        if any(not MIN_GRADIENT <= value <= MAX_GRADIENT for value in gradients):
            return None
        events.append((param_id, params, gradients))

    if seen_ids != set(range(group_count)):
        return None
    return (
        group_count,
        rows,
        columns,
        ns_steps,
        learning_rate,
        momentum,
        events,
    )


def _update_trace(
    group_count: int,
    rows: int,
    columns: int,
    ns_steps: int,
    learning_rate: float,
    momentum: float,
    events: Sequence[tuple[int, Sequence[float], Sequence[float]]],
) -> list[float]:
    matrix_elements = rows * columns
    velocity_by_id: dict[int, list[float]] = {}
    params_by_id: dict[int, list[float]] = {}
    for param_id, params, gradients in events:
        old_velocity = velocity_by_id.get(param_id)
        if old_velocity is None:
            old_velocity = [0.0] * matrix_elements
        orthogonalized_gradient = _orthogonalize(gradients, rows, columns, ns_steps)
        velocity = [
            momentum * old_velocity[index] + orthogonalized_gradient[index]
            for index in range(matrix_elements)
        ]
        updated_params = [
            params[index] - learning_rate * velocity[index]
            for index in range(matrix_elements)
        ]
        velocity_by_id[param_id] = velocity
        params_by_id[param_id] = updated_params

    output: list[float] = []
    for param_id in range(group_count):
        output.extend(params_by_id[param_id])
    for param_id in range(group_count):
        output.extend(velocity_by_id[param_id])
    return output


def expected_result(values: Sequence[int | float] | None) -> list[float] | None:
    """Return final parameter matrices, then retained velocities by ID."""
    parsed = _parse(values)
    if parsed is None:
        return None
    group_count, rows, columns, ns_steps, learning_rate, momentum, events = parsed
    output = _update_trace(
        group_count, rows, columns, ns_steps, learning_rate, momentum, events
    )
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
    """Return status and the flattened final parameter/velocity matrices."""
    if type(output_is_null) is not bool or type(input_is_null) is not bool:
        return INVALID_RESULT, []
    if output_capacity is not None and (
        type(output_capacity) is not int or output_capacity < 0
    ):
        return INVALID_RESULT, []
    if input_length is not None and (type(input_length) is not int or input_length < 0):
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
