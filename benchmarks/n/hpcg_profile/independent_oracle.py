"""Dense independent oracle and output verifier for the HPCG profile."""

from __future__ import annotations

import math
import struct

MAX_N = 32
MAX_STEPS = 12
MAX_MICRO = 1_000_000_000
MAX_INPUT_LENGTH = 452
MAX_OUTPUT_BYTES = 264
SCALE = 1_000_000.0
ABSOLUTE_TOLERANCE = 1.0e-8
RELATIVE_TOLERANCE = 1.0e-8


def _parse_dense(values, input_is_null=False, input_length=None):
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
            or not n <= nnz <= 6 * n or input_length != 4 + 2 * n + 2 * nnz):
        return None
    rp = values[3:4 + n]
    ci_start = 4 + n
    columns = values[ci_start:ci_start + nnz]
    values_start = ci_start + nnz
    coefficients = values[values_start:values_start + nnz]
    rhs_micro = values[values_start + nnz:]
    if len(rp) != n + 1 or len(rhs_micro) != n or rp[0] != 0 or rp[-1] != nnz:
        return None
    dense_i = [[0] * n for _ in range(n)]
    for row in range(n):
        begin, end = rp[row], rp[row + 1]
        if not 0 <= begin < end <= nnz or end - begin > 6:
            return None
        last = -1
        for edge in range(begin, end):
            col, coefficient = columns[edge], coefficients[edge]
            if (not 0 <= col < n or col <= last or coefficient == 0
                    or not -MAX_MICRO <= coefficient <= MAX_MICRO):
                return None
            dense_i[row][col] = coefficient
            last = col
    for row in range(n):
        if (dense_i[row][row] <= 0
                or dense_i[row][row] <= sum(abs(dense_i[row][col])
                                            for col in range(n) if col != row)):
            return None
        for col in range(n):
            if dense_i[row][col] != dense_i[col][row]:
                return None
    if any(not -MAX_MICRO <= value <= MAX_MICRO for value in rhs_micro):
        return None
    return n, steps, [[value / SCALE for value in row] for row in dense_i], [v / SCALE for v in rhs_micro]


def _dense_mv(matrix, vector):
    return [sum(a * x for a, x in zip(row, vector)) for row in matrix]


def _gaussian_solve(matrix, rhs):
    size = len(rhs)
    augmented = [row[:] + [rhs[index]] for index, row in enumerate(matrix)]
    for pivot in range(size):
        best = max(range(pivot, size), key=lambda row: abs(augmented[row][pivot]))
        if abs(augmented[best][pivot]) <= 0.0:
            return None
        augmented[pivot], augmented[best] = augmented[best], augmented[pivot]
        for row in range(pivot + 1, size):
            factor = augmented[row][pivot] / augmented[pivot][pivot]
            for col in range(pivot + 1, size + 1):
                augmented[row][col] -= factor * augmented[pivot][col]
    solution = [0.0] * size
    for row in range(size - 1, -1, -1):
        tail = sum(augmented[row][col] * solution[col]
                   for col in range(row + 1, size))
        solution[row] = (augmented[row][size] - tail) / augmented[row][row]
    return solution


def _precondition(matrix, residual):
    n = len(residual)
    diagonal = [matrix[i][i] for i in range(n)]
    # Independent dense pre-sweep, coarse correction, and symmetric post-sweep.
    forward = [0.0] * n
    for row in range(n):
        subtotal = sum(matrix[row][col] * forward[col] for col in range(row))
        forward[row] = (residual[row] - subtotal) / diagonal[row]
    after_pre = [residual[i] - value for i, value in enumerate(_dense_mv(matrix, forward))]
    coarse_n = (n + 1) // 2
    coarse = [[0.0] * coarse_n for _ in range(coarse_n)]
    coarse_rhs = [0.0] * coarse_n
    for row in range(n):
        coarse_rhs[row // 2] += after_pre[row]
        for col in range(n):
            coarse[row // 2][col // 2] += matrix[row][col]
    correction = _gaussian_solve(coarse, coarse_rhs)
    if correction is None:
        return None
    middle = [forward[i] + correction[i // 2] for i in range(n)]
    after_coarse = [residual[i] - value for i, value in enumerate(_dense_mv(matrix, middle))]
    post = [0.0] * n
    for row in range(n - 1, -1, -1):
        subtotal = sum(matrix[row][col] * post[col] for col in range(row + 1, n))
        post[row] = (after_coarse[row] - subtotal) / diagonal[row]
    return [middle[i] + post[i] for i in range(n)]


def _run(parsed):
    n, steps, matrix, b = parsed
    x = [0.0] * n
    residual = b[:]
    b2 = sum(value * value for value in b)
    if b2 == 0.0:
        return x + [0.0]
    z = _precondition(matrix, residual)
    if z is None:
        return None
    direction = z[:]
    rho = sum(residual[i] * z[i] for i in range(n))
    if not rho > 0.0 or not math.isfinite(rho):
        return None
    for _ in range(steps):
        product = _dense_mv(matrix, direction)
        curvature = sum(direction[i] * product[i] for i in range(n))
        if not curvature > 0.0 or not math.isfinite(curvature):
            return None
        scale = rho / curvature
        x = [x[i] + scale * direction[i] for i in range(n)]
        residual = [residual[i] - scale * product[i] for i in range(n)]
        new_r2 = sum(value * value for value in residual)
        if new_r2 <= b2 * 1.0e-28:
            break
        next_z = _precondition(matrix, residual)
        if next_z is None:
            return None
        next_rho = sum(residual[i] * next_z[i] for i in range(n))
        if not next_rho > 0.0 or not math.isfinite(next_rho):
            return None
        factor = next_rho / rho
        direction = [next_z[i] + factor * direction[i] for i in range(n)]
        z, rho = next_z, next_rho
    true_r = [b[i] - value for i, value in enumerate(_dense_mv(matrix, x))]
    norm = math.sqrt(sum(value * value for value in true_r))
    if not math.isfinite(norm) or not all(math.isfinite(value) for value in x):
        return None
    return x + [norm]


def expected_output(values, output_capacity=None, output_is_null=False,
                    input_is_null=False, input_length=None):
    parsed = _parse_dense(values, input_is_null, input_length)
    if parsed is None:
        return -1, b""
    required = 8 * (parsed[0] + 1)
    capacity = MAX_OUTPUT_BYTES if output_capacity is None else output_capacity
    if type(output_is_null) is not bool or type(capacity) is not int or capacity < 0:
        return -2, b""
    if output_is_null or capacity < required:
        return -2, b""
    output = _run(parsed)
    if output is None:
        return -1, b""
    return required, struct.pack("<" + "d" * len(output), *output)


def validate_output(values, payload, **abi_options):
    status, expected = expected_output(values, **abi_options)
    if status < 0:
        return payload == b""
    if not isinstance(payload, (bytes, bytearray)) or len(payload) != status:
        return False
    actual = struct.unpack("<" + "d" * (status // 8), payload)
    target = struct.unpack("<" + "d" * (status // 8), expected)
    return all(math.isfinite(a) and abs(a - e) <= ABSOLUTE_TOLERANCE + RELATIVE_TOLERANCE * abs(e)
               for a, e in zip(actual, target))


def verify_result(values, result, output, **abi_options):
    status, _expected = expected_output(values, **abi_options)
    if status < 0:
        return result == status and output == b""
    return result == status and validate_output(values, output, **abi_options)
