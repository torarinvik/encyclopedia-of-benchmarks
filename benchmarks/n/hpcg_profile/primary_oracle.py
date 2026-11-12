"""CSR primary oracle for the bounded coupled HPCG profile."""

from __future__ import annotations

import math
import struct
from collections.abc import Sequence

MAX_N = 32
MAX_STEPS = 12
MAX_NNZ_PER_ROW = 6
MAX_MICRO = 1_000_000_000
SCALE = 1_000_000.0
MAX_INPUT_LENGTH = 452
MAX_OUTPUT_BYTES = 8 * (MAX_N + 1)
ABSOLUTE_TOLERANCE = 1.0e-8
RELATIVE_TOLERANCE = 1.0e-8


def parse_input(values: Sequence[int] | None, input_is_null: bool = False,
                input_length: int | None = None):
    if input_is_null or not isinstance(values, (list, tuple)):
        return None
    if input_length is None:
        input_length = len(values)
    if (type(input_length) is not int or input_length != len(values)
            or not 8 <= input_length <= MAX_INPUT_LENGTH
            or any(type(word) is not int or not -(1 << 63) <= word < (1 << 63)
                   for word in values)):
        return None
    n, steps, nnz = values[:3]
    if (not 1 <= n <= MAX_N or not 1 <= steps <= min(MAX_STEPS, n)
            or not n <= nnz <= MAX_NNZ_PER_ROW * n
            or input_length != 4 + 2 * n + 2 * nnz):
        return None
    rp_start = 3
    col_start = rp_start + n + 1
    val_start = col_start + nnz
    rhs_start = val_start + nnz
    row_ptr = list(values[rp_start:col_start])
    columns = list(values[col_start:val_start])
    entries = list(values[val_start:rhs_start])
    rhs_micro = list(values[rhs_start:])
    if row_ptr[0] != 0 or row_ptr[-1] != nnz or len(rhs_micro) != n:
        return None
    diagonal = [0] * n
    rows: list[dict[int, int]] = []
    for row in range(n):
        begin, end = row_ptr[row:row + 2]
        if not 0 <= begin < end <= nnz or end - begin > MAX_NNZ_PER_ROW:
            return None
        row_values: dict[int, int] = {}
        off_diagonal_sum = 0
        previous_column = -1
        for edge in range(begin, end):
            column, value = columns[edge], entries[edge]
            if (not 0 <= column < n or column <= previous_column or value == 0
                    or not -MAX_MICRO <= value <= MAX_MICRO):
                return None
            previous_column = column
            row_values[column] = value
            if column == row:
                diagonal[row] = value
            else:
                off_diagonal_sum += abs(value)
        if diagonal[row] <= 0 or diagonal[row] <= off_diagonal_sum:
            return None
        rows.append(row_values)
    for row, row_values in enumerate(rows):
        for column, value in row_values.items():
            if rows[column].get(row) != value:
                return None
    if any(not -MAX_MICRO <= value <= MAX_MICRO for value in rhs_micro):
        return None
    return n, steps, nnz, row_ptr, columns, entries, rhs_micro, diagonal


def _matvec(parsed, vector: list[float]) -> list[float]:
    n, _steps, _nnz, row_ptr, columns, entries, _rhs, _diagonal = parsed
    product = [0.0] * n
    for row in range(n):
        total = 0.0
        for edge in range(row_ptr[row], row_ptr[row + 1]):
            total += entries[edge] / SCALE * vector[columns[edge]]
        product[row] = total
    return product


def _solve_coarse(parsed, coarse_rhs: list[float]) -> list[float] | None:
    n, _steps, _nnz, row_ptr, columns, entries, _rhs, _diagonal = parsed
    coarse_n = (n + 1) // 2
    matrix = [[0.0] * coarse_n for _ in range(coarse_n)]
    for row in range(n):
        coarse_row = row // 2
        for edge in range(row_ptr[row], row_ptr[row + 1]):
            coarse_column = columns[edge] // 2
            matrix[coarse_row][coarse_column] += entries[edge] / SCALE

    # Cholesky factorization of P^T A P, then two triangular solves.
    lower = [[0.0] * coarse_n for _ in range(coarse_n)]
    for row in range(coarse_n):
        for column in range(row + 1):
            value = matrix[row][column]
            for inner in range(column):
                value -= lower[row][inner] * lower[column][inner]
            if row == column:
                if not value > 0.0 or not math.isfinite(value):
                    return None
                lower[row][column] = math.sqrt(value)
            else:
                lower[row][column] = value / lower[column][column]
    intermediate = [0.0] * coarse_n
    for row in range(coarse_n):
        value = coarse_rhs[row]
        for column in range(row):
            value -= lower[row][column] * intermediate[column]
        intermediate[row] = value / lower[row][row]
    result = [0.0] * coarse_n
    for row in range(coarse_n - 1, -1, -1):
        value = intermediate[row]
        for column in range(row + 1, coarse_n):
            value -= lower[column][row] * result[column]
        result[row] = value / lower[row][row]
    return result


def _precondition(parsed, residual: list[float]) -> list[float] | None:
    n, _steps, _nnz, row_ptr, columns, entries, _rhs, diagonal = parsed
    # Forward Gauss-Seidel pre-sweep from a zero correction.
    y = [0.0] * n
    for row in range(n):
        value = residual[row]
        for edge in range(row_ptr[row], row_ptr[row + 1]):
            column = columns[edge]
            if column < row:
                value -= entries[edge] / SCALE * y[column]
        y[row] = value / (diagonal[row] / SCALE)
    pre_residual = [residual[i] - value for i, value in enumerate(_matvec(parsed, y))]
    coarse_n = (n + 1) // 2
    coarse_rhs = [0.0] * coarse_n
    for row, value in enumerate(pre_residual):
        coarse_rhs[row // 2] += value
    coarse_solution = _solve_coarse(parsed, coarse_rhs)
    if coarse_solution is None:
        return None
    middle = [y[row] + coarse_solution[row // 2] for row in range(n)]
    post_residual = [residual[i] - value for i, value in enumerate(_matvec(parsed, middle))]
    correction = [0.0] * n
    for row in range(n - 1, -1, -1):
        value = post_residual[row]
        for edge in range(row_ptr[row], row_ptr[row + 1]):
            column = columns[edge]
            if column > row:
                value -= entries[edge] / SCALE * correction[column]
        correction[row] = value / (diagonal[row] / SCALE)
    return [middle[row] + correction[row] for row in range(n)]


def _solve(parsed) -> list[float] | None:
    n, steps, _nnz, _rp, _cols, _entries, rhs_micro, _diagonal = parsed
    b = [value / SCALE for value in rhs_micro]
    x = [0.0] * n
    residual = b.copy()
    rhs_squared = sum(value * value for value in residual)
    if rhs_squared == 0.0:
        return x + [0.0]
    z = _precondition(parsed, residual)
    if z is None:
        return None
    direction = z.copy()
    rho = sum(residual[i] * z[i] for i in range(n))
    if not rho > 0.0 or not math.isfinite(rho):
        return None
    for _step in range(steps):
        product = _matvec(parsed, direction)
        denominator = sum(direction[i] * product[i] for i in range(n))
        if not denominator > 0.0 or not math.isfinite(denominator):
            return None
        alpha = rho / denominator
        for i in range(n):
            x[i] += alpha * direction[i]
            residual[i] -= alpha * product[i]
        next_squared = sum(value * value for value in residual)
        if next_squared <= rhs_squared * 1.0e-28:
            break
        z = _precondition(parsed, residual)
        if z is None:
            return None
        next_rho = sum(residual[i] * z[i] for i in range(n))
        if not next_rho > 0.0 or not math.isfinite(next_rho):
            return None
        beta = next_rho / rho
        for i in range(n):
            direction[i] = z[i] + beta * direction[i]
        rho = next_rho
    ax = _matvec(parsed, x)
    residual_norm = math.sqrt(sum((b[i] - ax[i]) ** 2 for i in range(n)))
    if not all(math.isfinite(value) for value in x) or not math.isfinite(residual_norm):
        return None
    return x + [residual_norm]


def expected_output(values, output_capacity=None, output_is_null=False,
                    input_is_null=False, input_length=None):
    parsed = parse_input(values, input_is_null, input_length)
    if parsed is None:
        return -1, b""
    required = 8 * (parsed[0] + 1)
    capacity = MAX_OUTPUT_BYTES if output_capacity is None else output_capacity
    if type(output_is_null) is not bool or type(capacity) is not int or capacity < 0:
        return -2, b""
    if output_is_null or capacity < required:
        return -2, b""
    result = _solve(parsed)
    if result is None:
        return -1, b""
    return required, struct.pack("<" + "d" * len(result), *result)


def expected_values(values, **abi_options):
    status, payload = expected_output(values, **abi_options)
    if status < 0:
        return status, []
    return status, list(struct.unpack("<" + "d" * (status // 8), payload))
