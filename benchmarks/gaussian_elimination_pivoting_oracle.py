"""Runtime oracle for the pinned row-pivoted elimination implementation."""
import math
import struct

MAX_DIMENSION = 4
MAX_INPUT_LENGTH = 1 + MAX_DIMENSION * (MAX_DIMENSION + 1)
MAX_OUTPUT_BYTES = MAX_DIMENSION * 8


def expected_output(values):
    if (not isinstance(values, (list, tuple)) or len(values) < 1
            or any(type(x) is not int or not -(2**63) <= x < 2**63 for x in values)):
        return -1, b""
    n = values[0]
    if not 2 <= n <= MAX_DIMENSION or len(values) != 1 + n * (n + 1):
        return -1, b""
    raw = values[1:]
    if any(abs(x) > 10000 for x in raw):
        return -1, b""
    matrix = [[raw[i * (n + 1) + j] / 1000.0 for j in range(n + 1)] for i in range(n)]
    for column in range(n):
        for row in range(column, n):
            if abs(matrix[row][column]) > abs(matrix[column][column]):
                matrix[column], matrix[row] = matrix[row], matrix[column]
        if abs(matrix[column][column]) < 1e-8:
            return -1, b""
        if column != 0:
            prior = column - 1
            for row in range(column, n):
                factor = matrix[row][prior] / matrix[prior][prior]
                for j in range(n + 1):
                    matrix[row][j] -= factor * matrix[prior][j]
    solution = [0.0] * n
    for column in range(n - 1, -1, -1):
        value = matrix[column][n] / matrix[column][column]
        solution[column] = value
        for row in range(column - 1, -1, -1):
            matrix[row][n] -= matrix[row][column] * value
    if any(not math.isfinite(x) for x in solution):
        return -1, b""
    return n * 8, struct.pack("<" + "d" * n, *solution)
