"""Independent exact-minor oracle for the bounded modular adjugate benchmark."""

from __future__ import annotations

import struct
from collections.abc import Sequence

MAX_N = 6
MODULUS = 998_244_353
MAX_INPUT_VALUES = 1 + MAX_N * MAX_N
MAX_OUTPUT_BYTES = 8 * MAX_N * MAX_N
INVALID_RESULT = -1
INSUFFICIENT_CAPACITY_RESULT = -2
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1


def _determinant(matrix: list[list[int]]) -> int:
    """Return an exact integer determinant by recursive first-row expansion."""
    size = len(matrix)
    if size == 0:
        return 1
    total = 0
    for column, value in enumerate(matrix[0]):
        if value == 0:
            continue
        minor = [row[:column] + row[column + 1 :] for row in matrix[1:]]
        term = value * _determinant(minor)
        total += term if column % 2 == 0 else -term
    return total


def _valid_matrix(values: Sequence[int] | None, input_length: int | None = None):
    if not isinstance(values, (list, tuple)):
        return None
    if any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values):
        return None
    if input_length is not None and (
        type(input_length) is not int or input_length != len(values)
    ):
        return None
    if not 2 <= len(values) <= MAX_INPUT_VALUES:
        return None
    n = values[0]
    if not 1 <= n <= MAX_N or len(values) != 1 + n * n:
        return None
    entries = values[1:]
    if any(not 0 <= value < MODULUS for value in entries):
        return None
    return [list(entries[row * n : (row + 1) * n]) for row in range(n)]


def expected_adjugate(values: Sequence[int] | None) -> list[int] | None:
    """Return the flattened row-major adjugate, or ``None`` for invalid input."""
    matrix = _valid_matrix(values)
    if matrix is None:
        return None
    n = len(matrix)
    result = [0] * (n * n)
    for row in range(n):
        for column in range(n):
            # adj(A)[row,column] is cofactor(A)[column,row].
            minor = [
                [value for j, value in enumerate(source_row) if j != row]
                for i, source_row in enumerate(matrix)
                if i != column
            ]
            cofactor = _determinant(minor)
            if (row + column) & 1:
                cofactor = -cofactor
            result[row * n + column] = cofactor % MODULUS
    return result


def certificate_holds(values: Sequence[int] | None, candidate: Sequence[int]) -> bool:
    """Check every output cell against its exact signed-minor certificate."""
    expected = expected_adjugate(values)
    return (
        expected is not None
        and isinstance(candidate, (list, tuple))
        and len(candidate) == len(expected)
        and all(type(value) is int for value in candidate)
        and list(candidate) == expected
    )


def expected_output(
    values: Sequence[int] | None,
    capacity: int | None = None,
    output_is_null: bool = False,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> tuple[int, bytes]:
    """Return ``(status, bytes)`` for ``[dimension, row-major matrix...]``."""
    if input_is_null:
        return INVALID_RESULT, b""
    matrix = _valid_matrix(values, input_length)
    if matrix is None:
        return INVALID_RESULT, b""
    if type(output_is_null) is not bool:
        return INSUFFICIENT_CAPACITY_RESULT, b""

    output_values = expected_adjugate(values)
    assert output_values is not None
    output = struct.pack("<" + "q" * len(output_values), *output_values)
    effective_capacity = len(output) if capacity is None else capacity
    if type(effective_capacity) is not int or effective_capacity < 0:
        return INSUFFICIENT_CAPACITY_RESULT, b""
    if output_is_null or effective_capacity < len(output):
        return INSUFFICIENT_CAPACITY_RESULT, b""
    return len(output), output
