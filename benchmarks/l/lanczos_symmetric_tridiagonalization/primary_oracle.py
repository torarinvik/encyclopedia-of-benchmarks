"""DLMF three-term Lanczos recurrence for a bounded symmetric matrix."""

from __future__ import annotations

import math
from collections.abc import Sequence

ALGORITHM = "lanczos_symmetric_tridiagonalization"
INVALID_RESULT = -1
OUTPUT_ERROR = -2
BREAKDOWN_RESULT = -3
MAX_ORDER = 4
MAX_STEPS = 4
MAX_VALID_INPUT_LENGTH = 18
MAX_PARSEABLE_INPUT_LENGTH = 19
MAX_OUTPUT_ELEMENTS = 8
WORKSPACE_ELEMENTS = 8
BREAKDOWN_THRESHOLD = 2.0 ** -40


def _finite_number(value: object) -> bool:
    if type(value) not in (int, float):
        return False
    try:
        return math.isfinite(float(value))
    except OverflowError:
        return False


def _exact_integer(value: object, low: int, high: int) -> int | None:
    if not _finite_number(value):
        return None
    number = float(value)
    if number < low or number > high or not number.is_integer():
        return None
    return int(number)


def _decode(values: Sequence[int | float] | None, input_is_null: bool,
            input_length: int | None) -> tuple[int, int, tuple[tuple[float, ...], ...]] | None:
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (tuple, list))
            or any(not _finite_number(value) for value in values)):
        return None
    length = len(values) if input_length is None else input_length
    if (type(length) is not int or length != len(values)
            or length < 3 or length > MAX_PARSEABLE_INPUT_LENGTH):
        return None
    n = _exact_integer(values[0], 1, MAX_ORDER)
    if n is None:
        return None
    k = _exact_integer(values[1], 1, n)
    if k is None or length != 2 + n * n:
        return None
    matrix: list[tuple[float, ...]] = []
    for row in range(n):
        entries: list[float] = []
        for col in range(n):
            entry = _exact_integer(values[2 + row * n + col], -4, 4)
            if entry is None:
                return None
            entries.append(float(entry))
        matrix.append(tuple(entries))
    if any(matrix[i][j] != matrix[j][i] for i in range(n) for j in range(i)):
        return None
    return n, k, tuple(matrix)


def _dot(left: Sequence[float], right: Sequence[float]) -> float:
    total = 0.0
    for index in range(len(left)):
        total += left[index] * right[index]
    return total


def _matvec(matrix: Sequence[Sequence[float]], vector: Sequence[float]) -> list[float]:
    result: list[float] = []
    for row in matrix:
        total = 0.0
        for col in range(len(vector)):
            total += row[col] * vector[col]
        result.append(total)
    return result


def _lanczos(n: int, steps: int, matrix: Sequence[Sequence[float]]) -> list[float] | None:
    previous = [0.0] * n
    current = [0.0] * n
    current[0] = 1.0
    previous_beta = 0.0
    diagonal: list[float] = []
    off_diagonal: list[float] = []
    for step in range(steps):
        product = _matvec(matrix, current)
        alpha = _dot(current, product)
        if not math.isfinite(alpha):
            return None
        diagonal.append(alpha)
        if step + 1 == steps:
            break
        residual = [0.0] * n
        for index in range(n):
            residual[index] = product[index] - alpha * current[index] - previous_beta * previous[index]
        squared_norm = _dot(residual, residual)
        if squared_norm < 0.0 or not math.isfinite(squared_norm):
            return None
        beta = math.sqrt(squared_norm)
        if beta <= BREAKDOWN_THRESHOLD or not math.isfinite(beta):
            return None
        off_diagonal.append(beta)
        next_vector = [residual[index] / beta for index in range(n)]
        if any(not math.isfinite(value) for value in next_vector):
            return None
        previous, current = current, next_vector
        previous_beta = beta
    return [float(steps), *diagonal, *off_diagonal]


def expected_output(values: Sequence[int | float] | None,
                    capacity: int | None = MAX_OUTPUT_ELEMENTS,
                    output_is_null: bool = False,
                    input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, tuple[float, ...]]:
    decoded = _decode(values, input_is_null, input_length)
    if decoded is None:
        return INVALID_RESULT, ()
    _, steps, _ = decoded
    required = 2 * steps
    if (type(output_is_null) is not bool or (capacity is not None and
            (type(capacity) is not int or capacity < 0))):
        return INVALID_RESULT, ()
    if output_is_null or (capacity is not None and capacity < required):
        return OUTPUT_ERROR, ()
    result = _lanczos(*decoded)
    if result is None:
        return BREAKDOWN_RESULT, ()
    return required, tuple(result)
