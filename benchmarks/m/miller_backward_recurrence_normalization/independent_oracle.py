"""Upper-triangular boundary-system reference for Miller's trial vector."""

from __future__ import annotations

import struct
from typing import Sequence

ALGORITHM = "miller_backward_recurrence_normalization"
MODULUS = 998244353
MIN_LEVELS = 1
MAX_LEVELS = 8
MIN_VALID_INPUT_LENGTH = 6
MAX_VALID_INPUT_LENGTH = 34
MAX_PARSEABLE_INPUT_LENGTH = 35
MAX_OUTPUT_BYTES = 80
WORKSPACE_BYTES = 192
INVALID_RESULT = -1
OUTPUT_ERROR_RESULT = -2


def _parse(values: Sequence[int] | None, input_is_null: bool,
           input_length: int | None) -> tuple[int, list[tuple[int, int, int]], list[int]] | None:
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple))
            or (input_length is not None
                and (type(input_length) is not int or input_length != len(values)))
            or not MIN_VALID_INPUT_LENGTH <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return None
    levels = values[0]
    if not MIN_LEVELS <= levels <= MAX_LEVELS or len(values) != 4 * levels + 2:
        return None
    if any(not 0 <= value < MODULUS for value in values[1:]):
        return None
    triples = [tuple(values[1 + 3 * index:4 + 3 * index]) for index in range(levels)]
    lambdas = list(values[3 * levels + 1:4 * levels + 2])
    if any(c_value == 0 for _, _, c_value in triples):
        return None
    return levels, triples, lambdas


def solve_boundary_system(triples: Sequence[tuple[int, int, int]]) -> list[int]:
    """Solve recurrence equations as a finite upper-triangular linear system."""
    levels = len(triples)
    matrix = [[0] * levels for _ in range(levels)]
    rhs = [0] * levels
    for n, (a_value, b_value, c_value) in enumerate(triples, start=1):
        row = n - 1
        matrix[row][row] = c_value
        if n < levels:
            matrix[row][n] = (MODULUS - b_value) % MODULUS
        else:
            rhs[row] = b_value
        if n + 1 < levels:
            matrix[row][n + 1] = a_value
        elif n + 1 == levels:
            rhs[row] = (rhs[row] - a_value) % MODULUS

    solution = [0] * levels
    for row in range(levels - 1, -1, -1):
        residual = rhs[row]
        for column in range(row + 1, levels):
            residual = (residual - matrix[row][column] * solution[column]) % MODULUS
        solution[row] = residual * pow(matrix[row][row], MODULUS - 2, MODULUS) % MODULUS
    return [*solution, 1]


def normalized_boundary_vector(triples: Sequence[tuple[int, int, int]],
                               lambdas: Sequence[int]) -> list[int] | None:
    trial = solve_boundary_system(triples)
    normalizer = sum(lambdas[index] * trial[index] for index in range(len(trial))) % MODULUS
    if normalizer == 0:
        return None
    inverse = pow(normalizer, MODULUS - 2, MODULUS)
    return [value * inverse % MODULUS for value in trial]


def expected_output(values: Sequence[int] | None,
                    capacity: int | None = None,
                    output_is_null: bool = False,
                    input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    parsed = _parse(values, input_is_null, input_length)
    if parsed is None:
        return INVALID_RESULT, b""
    levels, triples, lambdas = parsed
    normalized = normalized_boundary_vector(triples, lambdas)
    if normalized is None:
        return INVALID_RESULT, b""
    required = 8 * (levels + 2)
    effective_capacity = MAX_OUTPUT_BYTES if capacity is None else capacity
    if (type(output_is_null) is not bool or output_is_null
            or type(effective_capacity) is not int or effective_capacity < 0
            or effective_capacity < required):
        return OUTPUT_ERROR_RESULT, b""
    words = [levels, *normalized]
    return required, struct.pack("<" + "q" * len(words), *words)
