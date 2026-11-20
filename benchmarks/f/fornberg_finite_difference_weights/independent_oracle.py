"""Moment-system reference for arbitrary-node finite-difference weights."""

from __future__ import annotations

import struct
from collections.abc import Sequence

ALGORITHM = "fornberg_finite_difference_weights"
MODULUS = 998244353
MAX_NODES = 8
MAX_DERIVATIVE = 3
MAX_VALID_INPUT_LENGTH = MAX_NODES + 3
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_OUTPUT_BYTES = 8 * (MAX_NODES + 1)
WORKSPACE_BYTES = 1024
INVALID_RESULT = -1
OUTPUT_ERROR_RESULT = -2


def _decode(values: Sequence[int] | None, input_is_null: bool,
            input_length: int | None) -> tuple[int, int, int, list[int]] | None:
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple))
            or (input_length is not None
                and (type(input_length) is not int or input_length != len(values)))
            or len(values) < 4 or len(values) > MAX_PARSEABLE_INPUT_LENGTH
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return None
    count, derivative, point = values[0], values[1], values[2]
    if (count < 1 or count > MAX_NODES or derivative < 0
            or derivative > MAX_DERIVATIVE or derivative >= count
            or len(values) != count + 3):
        return None
    locations = list(values[3:])
    if (not 0 <= point < MODULUS
            or any(location < 0 or location >= MODULUS for location in locations)
            or len(set(locations)) != count):
        return None
    return count, derivative, point, locations


def moment_system_weights(nodes: Sequence[int], target: int, order: int) -> list[int]:
    """Solve the polynomial-exactness equations with modular Gauss-Jordan."""
    count = len(nodes)
    rhs = [0] * count
    factorial = 1
    for factor in range(1, order + 1):
        factorial = factorial * factor % MODULUS
    rhs[order] = factorial

    # Rows are powers and columns are nodes, so this is the direct moment system Vw=rhs.
    augmented = [
        [pow((node - target) % MODULUS, power, MODULUS) for node in nodes]
        + [rhs[power]]
        for power in range(count)
    ]
    for pivot_column in range(count):
        pivot_row = next((row for row in range(pivot_column, count)
                          if augmented[row][pivot_column] != 0), None)
        if pivot_row is None:
            raise ArithmeticError("distinct nodes produced a singular moment system")
        augmented[pivot_column], augmented[pivot_row] = (
            augmented[pivot_row], augmented[pivot_column]
        )
        scale = pow(augmented[pivot_column][pivot_column], MODULUS - 2, MODULUS)
        augmented[pivot_column] = [value * scale % MODULUS
                                   for value in augmented[pivot_column]]
        for row in range(count):
            if row == pivot_column:
                continue
            multiplier = augmented[row][pivot_column]
            if multiplier:
                augmented[row] = [
                    (left - multiplier * right) % MODULUS
                    for left, right in zip(augmented[row], augmented[pivot_column])
                ]
    return [augmented[row][-1] for row in range(count)]


def expected_output(values: Sequence[int] | None,
                    capacity: int | None = None,
                    output_is_null: bool = False,
                    input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    parsed = _decode(values, input_is_null, input_length)
    if parsed is None:
        return INVALID_RESULT, b""
    count, order, target, nodes = parsed
    weights = moment_system_weights(nodes, target, order)
    required = 8 * (count + 1)
    effective_capacity = MAX_OUTPUT_BYTES if capacity is None else capacity
    if (type(output_is_null) is not bool or output_is_null
            or type(effective_capacity) is not int or effective_capacity < required):
        return OUTPUT_ERROR_RESULT, b""
    return required, struct.pack("<" + "q" * (count + 1), count, *weights)
