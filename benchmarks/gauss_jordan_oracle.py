"""Runtime oracle for the pinned Gauss-Jordan coefficient/RHS reduction."""
import math
import struct

MAX_ROWS = 4
MAX_COLUMNS = 4
MAX_INPUT_LENGTH = 2 + MAX_ROWS * MAX_COLUMNS + MAX_ROWS
MAX_OUTPUT_BYTES = (MAX_ROWS * MAX_COLUMNS + MAX_ROWS) * 8


def expected_output(values):
    if (not isinstance(values, (list, tuple)) or len(values) < 2
            or any(type(x) is not int or not -(2**63) <= x < 2**63 for x in values)):
        return -1, b""
    rows, columns = values[:2]
    if not 1 <= rows <= MAX_ROWS or not 1 <= columns <= MAX_COLUMNS:
        return -1, b""
    if len(values) != 2 + rows * columns + rows:
        return -1, b""
    raw = values[2:]
    if any(abs(x) > 5000 for x in raw):
        return -1, b""
    coeff = [[raw[i * columns + j] / 1000.0 for j in range(columns)] for i in range(rows)]
    rhs = [raw[rows * columns + i] / 1000.0 for i in range(rows)]
    for column in range(columns):
        pivot = next((row for row in range(column, rows) if abs(coeff[row][column]) > 1e-8), None)
        if pivot is None:
            continue
        if pivot != column:
            coeff[column], coeff[pivot] = coeff[pivot], coeff[column]
            rhs[column], rhs[pivot] = rhs[pivot], rhs[column]
        pivot_value = coeff[column][column]
        coeff[column] = [x / pivot_value for x in coeff[column]]
        rhs[column] /= pivot_value
        for row in range(rows):
            if row == column:
                continue
            factor = coeff[row][column]
            coeff[row] = [coeff[row][j] - factor * coeff[column][j] for j in range(columns)]
            rhs[row] -= factor * rhs[column]
    result = [x for row in coeff for x in row] + rhs
    if any(not math.isfinite(x) for x in result):
        return -1, b""
    return len(result) * 8, struct.pack("<" + "d" * len(result), *result)
