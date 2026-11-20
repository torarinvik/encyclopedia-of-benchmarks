"""Krylov-power basis and projected-matrix reference for bounded Lanczos."""

from __future__ import annotations

import math
from collections.abc import Sequence

INVALID_RESULT = -1
OUTPUT_ERROR = -2
BREAKDOWN_RESULT = -3
MAX_ORDER = 4
MAX_VALID_INPUT_LENGTH = 18
MAX_PARSEABLE_INPUT_LENGTH = 19
MAX_OUTPUT_ELEMENTS = 8
BREAKDOWN_THRESHOLD = 2.0 ** -40


def _as_integer(value: object, low: int, high: int) -> int | None:
    if type(value) not in (int, float) or not math.isfinite(float(value)):
        return None
    number = float(value)
    if not number.is_integer() or number < low or number > high:
        return None
    return int(number)


def _parse(values: Sequence[int | float] | None, null_input: bool,
           length: int | None) -> tuple[int, int, list[list[float]]] | None:
    if (type(null_input) is not bool or null_input
            or not isinstance(values, (tuple, list))):
        return None
    for value in values:
        if type(value) not in (int, float):
            return None
        try:
            if not math.isfinite(float(value)):
                return None
        except OverflowError:
            return None
    framed = len(values) if length is None else length
    if type(framed) is not int or framed != len(values) or not 3 <= framed <= MAX_PARSEABLE_INPUT_LENGTH:
        return None
    order = _as_integer(values[0], 1, MAX_ORDER)
    if order is None:
        return None
    count = _as_integer(values[1], 1, order)
    if count is None or framed != 2 + order * order:
        return None
    entries: list[list[float]] = []
    for row in range(order):
        line: list[float] = []
        for col in range(order):
            cell = _as_integer(values[2 + row * order + col], -4, 4)
            if cell is None:
                return None
            line.append(float(cell))
        entries.append(line)
    for row in range(order):
        for col in range(row):
            if entries[row][col] != entries[col][row]:
                return None
    return order, count, entries


def _product(matrix: Sequence[Sequence[float]], vector: Sequence[float]) -> list[float]:
    return [sum(matrix[row][col] * vector[col] for col in range(len(vector)))
            for row in range(len(vector))]


def _inner(left: Sequence[float], right: Sequence[float]) -> float:
    return sum(left[index] * right[index] for index in range(len(left)))


def _projected_trace(order: int, count: int,
                     matrix: Sequence[Sequence[float]]) -> list[float] | None:
    power = [0.0] * order
    power[0] = 1.0
    basis: list[list[float]] = []
    for column in range(count):
        candidate = power.copy()
        for _ in range(2):
            for vector in basis:
                coefficient = _inner(vector, candidate)
                for row in range(order):
                    candidate[row] -= coefficient * vector[row]
        norm_squared = _inner(candidate, candidate)
        if norm_squared < 0.0 or not math.isfinite(norm_squared):
            return None
        norm = math.sqrt(norm_squared)
        if norm <= BREAKDOWN_THRESHOLD or not math.isfinite(norm):
            return None
        basis.append([value / norm for value in candidate])
        if column + 1 < count:
            power = _product(matrix, power)

    diagonal: list[float] = []
    off_diagonal: list[float] = []
    products: list[list[float]] = []
    for vector in basis:
        applied = _product(matrix, vector)
        products.append(applied)
        diagonal.append(_inner(vector, applied))
    for index in range(count - 1):
        beta = _inner(basis[index + 1], products[index])
        if not math.isfinite(beta) or abs(beta) <= BREAKDOWN_THRESHOLD:
            return None
        off_diagonal.append(abs(beta))
    if any(not math.isfinite(value) for value in diagonal):
        return None
    return [float(count), *diagonal, *off_diagonal]


def expected_output(values: Sequence[int | float] | None,
                    capacity: int | None = MAX_OUTPUT_ELEMENTS,
                    output_is_null: bool = False,
                    input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, tuple[float, ...]]:
    decoded = _parse(values, input_is_null, input_length)
    if decoded is None:
        return INVALID_RESULT, ()
    _, count, _ = decoded
    required = 2 * count
    if (type(output_is_null) is not bool or (capacity is not None and
            (type(capacity) is not int or capacity < 0))):
        return INVALID_RESULT, ()
    if output_is_null or (capacity is not None and capacity < required):
        return OUTPUT_ERROR, ()
    result = _projected_trace(*decoded)
    if result is None:
        return BREAKDOWN_RESULT, ()
    return required, tuple(result)
