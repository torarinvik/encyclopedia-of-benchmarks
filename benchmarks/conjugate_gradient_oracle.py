"""Exact bounded oracle for the conjugate-gradient linear solver."""

from __future__ import annotations

from fractions import Fraction
import struct

MAX_DIMENSION = 8
MAX_ENTRY_MICRO = 1_000_000_000
SCALE = 1_000_000
MAX_INPUT_LENGTH = 1 + MAX_DIMENSION * MAX_DIMENSION + MAX_DIMENSION
MAX_OUTPUT_BYTES = MAX_DIMENSION * 8


def expected_output(values: list[int] | tuple[int, ...],
                    capacity: int | None = None) -> tuple[int, bytes]:
    """Solve a bounded symmetric strictly diagonally dominant system exactly."""
    if (not isinstance(values, (list, tuple)) or not 1 <= len(values) <= MAX_INPUT_LENGTH
            or any(type(value) is not int or not -(2**63) <= value < 2**63 for value in values)):
        return -1, b""
    n = values[0]
    if not 1 <= n <= MAX_DIMENSION or len(values) != 1 + n * n + n:
        return -1, b""
    packed = values[1:]
    if any(not -MAX_ENTRY_MICRO <= value <= MAX_ENTRY_MICRO for value in packed):
        return -1, b""
    matrix_values = [packed[row * n:(row + 1) * n] for row in range(n)]
    for row in range(n):
        if matrix_values[row][row] <= 0:
            return -1, b""
        off_diagonal_sum = 0
        for column in range(n):
            if matrix_values[row][column] != matrix_values[column][row]:
                return -1, b""
            if column != row:
                off_diagonal_sum += abs(matrix_values[row][column])
        if matrix_values[row][row] <= off_diagonal_sum:
            return -1, b""

    augmented = [[Fraction(matrix_values[row][column]) for column in range(n)]
                 + [Fraction(packed[n * n + row])] for row in range(n)]
    for pivot in range(n):
        selected = next((row for row in range(pivot, n) if augmented[row][pivot]), None)
        if selected is None:
            return -1, b""
        augmented[pivot], augmented[selected] = augmented[selected], augmented[pivot]
        divisor = augmented[pivot][pivot]
        augmented[pivot] = [value / divisor for value in augmented[pivot]]
        for row in range(n):
            if row == pivot:
                continue
            factor = augmented[row][pivot]
            if factor:
                augmented[row] = [left - factor * right
                                  for left, right in zip(augmented[row], augmented[pivot])]
    solution = [float(augmented[row][n]) for row in range(n)]
    output = struct.pack("<" + "d" * n, *solution)
    if capacity is not None:
        if type(capacity) is not int or capacity < 0:
            return -1, b""
        if len(output) > capacity:
            return -2, b""
    return len(output), output
