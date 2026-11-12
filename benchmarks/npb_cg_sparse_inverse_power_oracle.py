"""Primary oracle for a bounded sparse inverse-power/CG kernel profile."""

from __future__ import annotations

import math
import struct
from collections.abc import Sequence

MAX_N = 32
MAX_OUTER_ITERATIONS = 8
MAX_CG_STEPS = 25
MAX_NNZ_PER_ROW = 6
MAX_ENTRY_MICRO = 1_000_000_000
SCALE = 1_000_000.0
MAX_INPUT_LENGTH = MAX_N + 6 + 2 * (MAX_N * MAX_NNZ_PER_ROW)
MAX_OUTPUT_BYTES = 16 * MAX_OUTER_ITERATIONS
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
    n, outer_count, cg_steps, shift_micro, nnz = values[:5]
    if (not 1 <= n <= MAX_N or not 1 <= outer_count <= MAX_OUTER_ITERATIONS
            or not 1 <= cg_steps <= min(MAX_CG_STEPS, n)
            or not -MAX_ENTRY_MICRO <= shift_micro <= MAX_ENTRY_MICRO
            or not n <= nnz <= MAX_NNZ_PER_ROW * n
            or len(values) != n + 6 + 2 * nnz):
        return None
    row_ptr_start = 5
    column_start = row_ptr_start + n + 1
    entry_start = column_start + nnz
    row_ptr = list(values[row_ptr_start:column_start])
    columns = list(values[column_start:entry_start])
    entries = list(values[entry_start:])
    if row_ptr[0] != 0 or row_ptr[-1] != nnz:
        return None
    diagonal = [0] * n
    for row in range(n):
        begin, end = row_ptr[row:row + 2]
        if not 0 <= begin < end <= nnz:
            return None
        off_diagonal_sum = 0
        previous_column = -1
        for edge in range(begin, end):
            column, value = columns[edge], entries[edge]
            if (not 0 <= column < n or column <= previous_column or value == 0
                    or not -MAX_ENTRY_MICRO <= value <= MAX_ENTRY_MICRO):
                return None
            previous_column = column
            if column == row:
                diagonal[row] = value
            else:
                off_diagonal_sum += abs(value)
        if diagonal[row] <= 0 or diagonal[row] <= off_diagonal_sum:
            return None
    positions = [dict(zip(columns[row_ptr[row]:row_ptr[row + 1]],
                           entries[row_ptr[row]:row_ptr[row + 1]]))
                for row in range(n)]
    for row in range(n):
        for column, value in positions[row].items():
            if positions[column].get(row) != value:
                return None
    return n, outer_count, cg_steps, shift_micro, nnz, row_ptr, columns, entries


def _matvec(n, row_ptr, columns, entries, vector):
    product = [0.0] * n
    for row in range(n):
        total = 0.0
        for edge in range(row_ptr[row], row_ptr[row + 1]):
            total += (entries[edge] / SCALE) * vector[columns[edge]]
        product[row] = total
    return product


def _solve(parsed):
    n, outer_count, cg_steps, shift_micro, _nnz, row_ptr, columns, entries = parsed
    x = [1.0] * n
    output = []
    for _outer in range(outer_count):
        z = [0.0] * n
        residual = x.copy()
        direction = x.copy()
        rhs_squared = sum(value * value for value in residual)
        residual_squared = rhs_squared
        for _step in range(cg_steps):
            if residual_squared <= 0.0:
                break
            product = _matvec(n, row_ptr, columns, entries, direction)
            denominator = sum(direction[i] * product[i] for i in range(n))
            if not denominator > 0.0 or not math.isfinite(denominator):
                return None
            alpha = residual_squared / denominator
            for i in range(n):
                z[i] += alpha * direction[i]
                residual[i] -= alpha * product[i]
            next_squared = sum(value * value for value in residual)
            if next_squared <= rhs_squared * 1.0e-28:
                residual_squared = next_squared
                break
            beta = next_squared / residual_squared
            for i in range(n):
                direction[i] = residual[i] + beta * direction[i]
            residual_squared = next_squared
        az = _matvec(n, row_ptr, columns, entries, z)
        explicit_squared = sum((x[i] - az[i]) ** 2 for i in range(n))
        x_dot_z = sum(x[i] * z[i] for i in range(n))
        z_squared = sum(value * value for value in z)
        if (not x_dot_z > 0.0 or not z_squared > 0.0
                or not math.isfinite(x_dot_z) or not math.isfinite(z_squared)):
            return None
        eigenvalue = shift_micro / SCALE + 1.0 / x_dot_z
        residual_norm = math.sqrt(explicit_squared)
        if not math.isfinite(eigenvalue) or not math.isfinite(residual_norm):
            return None
        output.extend((eigenvalue, residual_norm))
        z_norm = math.sqrt(z_squared)
        x = [value / z_norm for value in z]
    return output


def expected_output(values, output_capacity=None, output_is_null=False,
                    input_is_null=False, input_length=None):
    parsed = parse_input(values, input_is_null, input_length)
    if parsed is None:
        return -1, b""
    required = 16 * parsed[1]
    capacity = MAX_OUTPUT_BYTES if output_capacity is None else output_capacity
    if (type(output_is_null) is not bool or type(capacity) is not int
            or capacity < 0):
        return -2, b""
    if output_is_null or capacity < required:
        return -2, b""
    result = _solve(parsed)
    if result is None:
        return -1, b""
    return required, struct.pack("<" + "d" * len(result), *result)


def expected_values(values, **abi_options):
    """Return the floating output records with the ABI status."""
    result, payload = expected_output(values, **abi_options)
    if result < 0:
        return result, []
    return result, list(struct.unpack("<" + "d" * (result // 8), payload))

