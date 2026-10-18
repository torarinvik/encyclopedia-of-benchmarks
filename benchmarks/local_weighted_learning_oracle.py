"""Oracle for the bounded local-weighted regression contract."""

from __future__ import annotations

from collections.abc import Sequence
import math

MAX_N = 16
MAX_D = 4
MAX_VALID_INPUT_LENGTH = 3 + MAX_N * MAX_D + MAX_N
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_OUTPUT_ELEMENTS = MAX_N
INVALID_RESULT = -1
OUTPUT_ERROR = -2
GRID_SCALE = 16.0
PIVOT_FLOOR = 2.0 ** -18
ABSOLUTE_TOLERANCE = 1e-8
RELATIVE_TOLERANCE = 1e-8


def _as_finite_float(value: object) -> float | None:
    if type(value) not in (int, float):
        return None
    try:
        result = float(value)
    except (OverflowError, ValueError):
        return None
    return result if math.isfinite(result) else None


def _on_grid(value: float) -> bool:
    scaled = value * GRID_SCALE
    return math.isfinite(scaled) and scaled.is_integer()


def _decode_input(values: Sequence[int | float] | None):
    if (
        not isinstance(values, (list, tuple))
        or not 3 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
    ):
        return None

    numeric = [_as_finite_float(value) for value in values]
    if any(value is None for value in numeric):
        return None
    packed = [value for value in numeric if value is not None]

    n_value, d_value, tau = packed[:3]
    if not n_value.is_integer() or not d_value.is_integer():
        return None
    n, d = int(n_value), int(d_value)
    if not (2 <= n <= MAX_N and 1 <= d <= MAX_D and d <= n):
        return None
    if len(packed) != 3 + n * d + n:
        return None
    if not (2.0 <= tau <= 8.0 and _on_grid(tau)):
        return None

    matrix_end = 3 + n * d
    matrix_values = packed[3:matrix_end]
    response_values = packed[matrix_end:]
    if any(not (-4.0 <= value <= 4.0 and _on_grid(value)) for value in matrix_values):
        return None
    if any(not (-8.0 <= value <= 8.0 and _on_grid(value)) for value in response_values):
        return None

    matrix = [matrix_values[row * d:(row + 1) * d] for row in range(n)]
    return n, d, tau, matrix, response_values


def _solve_partial_pivot(matrix: list[list[float]], rhs: list[float]) -> list[float] | None:
    """Solve a small system using the contract's fixed binary64 loop order."""
    d = len(rhs)
    scale = 0.0
    for index in range(d):
        diagonal = abs(matrix[index][index])
        if diagonal > scale:
            scale = diagonal
    if not math.isfinite(scale) or scale == 0.0:
        return None

    for pivot_column in range(d):
        pivot_row = pivot_column
        pivot_magnitude = abs(matrix[pivot_row][pivot_column])
        for candidate_row in range(pivot_column + 1, d):
            candidate_magnitude = abs(matrix[candidate_row][pivot_column])
            if candidate_magnitude > pivot_magnitude:
                pivot_row = candidate_row
                pivot_magnitude = candidate_magnitude
        if (
            not math.isfinite(pivot_magnitude)
            or pivot_magnitude <= PIVOT_FLOOR * scale
        ):
            return None

        if pivot_row != pivot_column:
            matrix[pivot_column], matrix[pivot_row] = matrix[pivot_row], matrix[pivot_column]
            rhs[pivot_column], rhs[pivot_row] = rhs[pivot_row], rhs[pivot_column]

        pivot = matrix[pivot_column][pivot_column]
        for row in range(pivot_column + 1, d):
            factor = matrix[row][pivot_column] / pivot
            if not math.isfinite(factor):
                return None
            matrix[row][pivot_column] = 0.0
            for column in range(pivot_column + 1, d):
                product = factor * matrix[pivot_column][column]
                matrix[row][column] = matrix[row][column] - product
                if not math.isfinite(matrix[row][column]):
                    return None
            product = factor * rhs[pivot_column]
            rhs[row] = rhs[row] - product
            if not math.isfinite(rhs[row]):
                return None

    coefficients = [0.0] * d
    for row in range(d - 1, -1, -1):
        residual = rhs[row]
        for column in range(row + 1, d):
            product = matrix[row][column] * coefficients[column]
            residual = residual - product
        diagonal = matrix[row][row]
        if not math.isfinite(residual) or diagonal == 0.0 or not math.isfinite(diagonal):
            return None
        coefficients[row] = residual / diagonal
        if not math.isfinite(coefficients[row]):
            return None
    return coefficients


def _predict_all(
    n: int, d: int, tau: float, x_train: list[list[float]], y_train: list[float]
) -> list[float] | None:
    predictions: list[float] = []
    for query_index in range(n):
        weights: list[float] = []
        for row_index in range(n):
            distance_squared = 0.0
            for feature_index in range(d):
                delta = x_train[query_index][feature_index] - x_train[row_index][feature_index]
                squared_delta = delta * delta
                distance_squared = distance_squared + squared_delta
            tau_squared = tau * tau
            denominator = (-2.0) * tau_squared
            exponent = distance_squared / denominator
            weight = math.exp(exponent)
            if not math.isfinite(weight) or weight <= 0.0:
                return None
            weights.append(weight)

        normal = [[0.0 for _ in range(d)] for _ in range(d)]
        rhs = [0.0 for _ in range(d)]
        for row_index in range(n):
            weighted_x = [weights[row_index] * x_train[row_index][q] for q in range(d)]
            weighted_y = weights[row_index] * y_train[row_index]
            for p in range(d):
                rhs_product = x_train[row_index][p] * weighted_y
                rhs[p] = rhs[p] + rhs_product
                for q in range(d):
                    product = x_train[row_index][p] * weighted_x[q]
                    normal[p][q] = normal[p][q] + product

        if any(not math.isfinite(value) for row in normal for value in row):
            return None
        if any(not math.isfinite(value) for value in rhs):
            return None
        coefficients = _solve_partial_pivot(normal, rhs)
        if coefficients is None:
            return None

        prediction = 0.0
        for feature_index in range(d):
            product = x_train[query_index][feature_index] * coefficients[feature_index]
            prediction = prediction + product
        if not math.isfinite(prediction):
            return None
        predictions.append(prediction)
    return predictions


def expected_output(
    values: Sequence[int | float] | None,
    capacity: int | None = None,
    output_is_null: bool = False,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> tuple[int, list[float]]:
    """Return float64 predictions or the documented ABI error."""
    if type(output_is_null) is not bool or type(input_is_null) is not bool:
        return INVALID_RESULT, []
    if input_is_null or values is None or not isinstance(values, (list, tuple)):
        return INVALID_RESULT, []
    if input_length is not None and (
        type(input_length) is not int or input_length != len(values)
    ):
        return INVALID_RESULT, []

    decoded = _decode_input(values)
    if decoded is None:
        return INVALID_RESULT, []
    n, d, tau, x_train, y_train = decoded
    predictions = _predict_all(n, d, tau, x_train, y_train)
    if predictions is None:
        return INVALID_RESULT, []

    if capacity is not None and (type(capacity) is not int or capacity < 0):
        return INVALID_RESULT, []
    if output_is_null or (capacity is not None and capacity < n):
        return OUTPUT_ERROR, []
    return n, predictions
