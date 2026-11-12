"""Exact dense-arithmetic oracle for a bounded Thomas-algorithm workload."""

from __future__ import annotations

from fractions import Fraction
import math
import struct

MAX_N = 32
MAX_PARSEABLE_INPUT_LENGTH = 1 + 4 * MAX_N
MAX_OUTPUT_BYTES = 8 * MAX_N
MAX_OFF_DIAGONAL = 16
MIN_DIAGONAL = 17
MAX_DIAGONAL = 64
MAX_RHS = 1000


def _parse(values, input_is_null=False, input_length=None):
    if input_is_null:
        return None
    try:
        data = tuple(values)
    except TypeError:
        return None
    length = len(data) if input_length is None else input_length
    if (not isinstance(length, int) or length < 1
            or length > MAX_PARSEABLE_INPUT_LENGTH or length != len(data)):
        return None
    if any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
           for value in data):
        return None
    n = data[0]
    if not 1 <= n <= MAX_N or length != 1 + 4 * n:
        return None
    lower = data[1:1 + n]
    diagonal = data[1 + n:1 + 2 * n]
    upper = data[1 + 2 * n:1 + 3 * n]
    rhs = data[1 + 3 * n:1 + 4 * n]
    if lower[0] != 0 or upper[-1] != 0:
        return None
    if any(abs(value) > MAX_OFF_DIAGONAL for value in (*lower, *upper)):
        return None
    if any(not MIN_DIAGONAL <= value <= MAX_DIAGONAL for value in diagonal):
        return None
    if any(not -MAX_RHS <= value <= MAX_RHS for value in rhs):
        return None
    if any(diagonal[i] <= abs(lower[i]) + abs(upper[i]) for i in range(n)):
        return None
    return n, lower, diagonal, upper, rhs


def _dense_fraction_solution(n, lower, diagonal, upper, rhs):
    """Solve with dense exact Gaussian elimination and partial pivoting."""
    matrix = [[Fraction(0) for _ in range(n + 1)] for _ in range(n)]
    for row in range(n):
        matrix[row][row] = Fraction(diagonal[row])
        if row > 0:
            matrix[row][row - 1] = Fraction(lower[row])
        if row + 1 < n:
            matrix[row][row + 1] = Fraction(upper[row])
        matrix[row][n] = Fraction(rhs[row])

    for column in range(n):
        pivot = max(range(column, n), key=lambda row: abs(matrix[row][column]))
        if matrix[pivot][column] == 0:
            return None
        matrix[column], matrix[pivot] = matrix[pivot], matrix[column]
        for row in range(column + 1, n):
            if matrix[row][column] == 0:
                continue
            factor = matrix[row][column] / matrix[column][column]
            for entry in range(column, n + 1):
                matrix[row][entry] -= factor * matrix[column][entry]

    answer = [Fraction(0) for _ in range(n)]
    for row in range(n - 1, -1, -1):
        residual = matrix[row][n] - sum(
            matrix[row][column] * answer[column]
            for column in range(row + 1, n))
        if matrix[row][row] == 0:
            return None
        answer[row] = residual / matrix[row][row]
    return answer


def expected_output(values, output_capacity=None, output_is_null=False,
                    input_is_null=False, input_length=None):
    parsed = _parse(values, input_is_null, input_length)
    if parsed is None:
        return -1, b""
    n, lower, diagonal, upper, rhs = parsed
    answer = _dense_fraction_solution(n, lower, diagonal, upper, rhs)
    if answer is None:
        return -1, b""
    payload = b"".join(struct.pack("<d", float(value)) for value in answer)
    effective_capacity = MAX_OUTPUT_BYTES if output_capacity is None else output_capacity
    if (type(output_is_null) is not bool or type(effective_capacity) is not int
            or effective_capacity < 0):
        return -2, b""
    if output_is_null or effective_capacity < len(payload):
        return -2, b""
    return len(payload), payload


def validate_output(values, output: bytes) -> bool:
    parsed = _parse(values)
    if parsed is None:
        return False
    result, expected = expected_output(values, MAX_OUTPUT_BYTES)
    if result < 0 or len(output) != result:
        return False
    n, lower, diagonal, upper, rhs = parsed
    solution = struct.unpack("<" + "d" * n, output)
    if any(not math.isfinite(value) for value in solution):
        return False
    for row, value in enumerate(solution):
        residual = diagonal[row] * value + lower[row] * (solution[row - 1] if row else 0.0)
        residual += upper[row] * (solution[row + 1] if row + 1 < n else 0.0)
        if abs(residual - rhs[row]) > 1.0e-9 + 1.0e-9 * abs(rhs[row]):
            return False
    return output == expected or all(
        abs(actual - target) <= 1.0e-9 + 1.0e-9 * abs(target)
        for actual, target in zip(solution, struct.unpack("<" + "d" * n, expected)))
