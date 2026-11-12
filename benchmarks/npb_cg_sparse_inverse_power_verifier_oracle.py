"""Independent dense-matrix oracle and output certificate for bounded NPB CG."""

from __future__ import annotations

import math
import struct

MAX_N = 32
MAX_OUTER_ITERATIONS = 8
MAX_CG_STEPS = 25
MAX_NNZ_PER_ROW = 6
MAX_ENTRY_MICRO = 1_000_000_000
MAX_INPUT_LENGTH = MAX_N + 6 + 2 * (MAX_N * MAX_NNZ_PER_ROW)
MAX_OUTPUT_BYTES = 16 * MAX_OUTER_ITERATIONS
SCALE = 1_000_000.0
ABSOLUTE_TOLERANCE = 1.0e-8
RELATIVE_TOLERANCE = 1.0e-8


def _dense_input(values, input_is_null=False, input_length=None):
    if input_is_null or not isinstance(values, (list, tuple)):
        return None
    if input_length is None:
        input_length = len(values)
    if (type(input_length) is not int or input_length != len(values)
            or not 8 <= input_length <= MAX_INPUT_LENGTH
            or any(type(word) is not int or not -(1 << 63) <= word < (1 << 63)
                   for word in values)):
        return None
    n, outer_count, steps, shift, nnz = values[:5]
    if (not 1 <= n <= MAX_N or not 1 <= outer_count <= MAX_OUTER_ITERATIONS
            or not 1 <= steps <= min(MAX_CG_STEPS, n)
            or not -MAX_ENTRY_MICRO <= shift <= MAX_ENTRY_MICRO
            or not n <= nnz <= MAX_NNZ_PER_ROW * n
            or input_length != n + 6 + 2 * nnz):
        return None
    rp_start = 5
    col_start = rp_start + n + 1
    val_start = col_start + nnz
    pointers = values[rp_start:col_start]
    indices = values[col_start:val_start]
    coefficients = values[val_start:]
    if len(pointers) != n + 1 or pointers[0] != 0 or pointers[-1] != nnz:
        return None
    dense = [[0] * n for _ in range(n)]
    for row in range(n):
        begin, end = pointers[row], pointers[row + 1]
        if not 0 <= begin < end <= nnz:
            return None
        prior = -1
        for edge in range(begin, end):
            col, value = indices[edge], coefficients[edge]
            if (not 0 <= col < n or col <= prior or value == 0
                    or not -MAX_ENTRY_MICRO <= value <= MAX_ENTRY_MICRO):
                return None
            dense[row][col] = value
            prior = col
    for row in range(n):
        diagonal = dense[row][row]
        if diagonal <= 0 or diagonal <= sum(abs(dense[row][col]) for col in range(n) if col != row):
            return None
        for col in range(n):
            if dense[row][col] != dense[col][row]:
                return None
    return n, outer_count, steps, shift, dense


def _dense_product(matrix, vector):
    return [sum((entry / SCALE) * vector[column]
                for column, entry in enumerate(row)) for row in matrix]


def _dense_solution(parsed):
    n, outer_count, steps, shift, matrix = parsed
    vector = [1.0] * n
    records = []
    for _ in range(outer_count):
        solution = [0.0] * n
        residual = vector.copy()
        search = vector.copy()
        initial_norm_squared = sum(term * term for term in residual)
        norm_squared = initial_norm_squared
        step = 0
        while step < steps and norm_squared > 0.0:
            product = _dense_product(matrix, search)
            curvature = sum(search[index] * product[index] for index in range(n))
            if not curvature > 0.0 or not math.isfinite(curvature):
                return None
            amount = norm_squared / curvature
            for index in range(n):
                solution[index] += amount * search[index]
                residual[index] -= amount * product[index]
            following_norm_squared = sum(term * term for term in residual)
            if following_norm_squared <= initial_norm_squared * 1.0e-28:
                norm_squared = following_norm_squared
                break
            factor = following_norm_squared / norm_squared
            for index in range(n):
                search[index] = residual[index] + factor * search[index]
            norm_squared = following_norm_squared
            step += 1
        true_residual = [vector[index] - product_value
                         for index, product_value in enumerate(_dense_product(matrix, solution))]
        dot = sum(vector[index] * solution[index] for index in range(n))
        solution_norm_squared = sum(term * term for term in solution)
        if (not dot > 0.0 or not solution_norm_squared > 0.0
                or not math.isfinite(dot) or not math.isfinite(solution_norm_squared)):
            return None
        records.extend((shift / SCALE + 1.0 / dot,
                        math.sqrt(sum(term * term for term in true_residual))))
        length = math.sqrt(solution_norm_squared)
        vector = [term / length for term in solution]
    return records


def expected_output(values, output_capacity=None, output_is_null=False,
                    input_is_null=False, input_length=None):
    parsed = _dense_input(values, input_is_null, input_length)
    if parsed is None:
        return -1, b""
    required = 16 * parsed[1]
    capacity = MAX_OUTPUT_BYTES if output_capacity is None else output_capacity
    if (type(output_is_null) is not bool or type(capacity) is not int
            or capacity < 0):
        return -2, b""
    if output_is_null or capacity < required:
        return -2, b""
    records = _dense_solution(parsed)
    if records is None:
        return -1, b""
    return required, struct.pack("<" + "d" * len(records), *records)


def validate_output(values, payload, **abi_options):
    status, expected = expected_output(values, **abi_options)
    if status < 0:
        return payload == b""
    if not isinstance(payload, (bytes, bytearray)) or len(payload) != status:
        return False
    try:
        observed = struct.unpack("<" + "d" * (status // 8), payload)
        target = struct.unpack("<" + "d" * (status // 8), expected)
    except struct.error:
        return False
    for actual, reference in zip(observed, target):
        if (not math.isfinite(actual)
                or abs(actual - reference) > ABSOLUTE_TOLERANCE + RELATIVE_TOLERANCE * abs(reference)):
            return False
    return True


def verify_result(values, result, output, **abi_options):
    parsed = _dense_input(values, abi_options.get("input_is_null", False),
                          abi_options.get("input_length"))
    if parsed is None:
        return result == -1 and output == b""
    expected_status, _ = expected_output(values, **abi_options)
    if expected_status < 0:
        return result == expected_status and output == b""
    return result == expected_status and validate_output(values, output, **abi_options)

