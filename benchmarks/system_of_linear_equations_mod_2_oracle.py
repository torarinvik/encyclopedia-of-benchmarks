"""Scalar Boolean-elimination oracle for systems over GF(2).

The benchmark ports pack coefficient rows into machine words; this oracle
intentionally uses ordinary Boolean rows to keep the checker independent.
"""

import struct

MAX_N = 32
MAX_M = 32
MAX_PARSEABLE_INPUT_LENGTH = 2 + MAX_N * MAX_M + MAX_N
MAX_OUTPUT_BYTES = 8 * (MAX_M + 2)


def expected_output(values, capacity=None, output_is_null=False,
                    input_is_null=False, input_length=None):
    """Return ``(result, bytes)`` for ``[N, M, A row-major..., b...]``."""
    if input_is_null or not isinstance(values, (list, tuple)):
        return -1, b""
    if input_length is None:
        input_length = len(values)
    if (type(input_length) is not int or input_length < 2
            or input_length > MAX_PARSEABLE_INPUT_LENGTH
            or input_length != len(values)
            or any(type(value) is not int for value in values)):
        return -1, b""

    n, m = values[0], values[1]
    if not 1 <= n <= MAX_N or not 1 <= m <= MAX_M:
        return -1, b""
    if len(values) != 2 + n * m + n:
        return -1, b""
    coefficients = values[2:2 + n * m]
    right_hand_side = values[2 + n * m:]
    if any(bit not in (0, 1) for bit in coefficients + right_hand_side):
        return -1, b""

    rows = [list(coefficients[row * m:(row + 1) * m]) for row in range(n)]
    rhs = list(right_hand_side)
    pivot_columns = []
    pivot_row = 0
    for column in range(m):
        pivot = next((row for row in range(pivot_row, n) if rows[row][column]), None)
        if pivot is None:
            continue
        rows[pivot_row], rows[pivot] = rows[pivot], rows[pivot_row]
        rhs[pivot_row], rhs[pivot] = rhs[pivot], rhs[pivot_row]
        for row in range(n):
            if row != pivot_row and rows[row][column]:
                rows[row] = [left ^ right for left, right in zip(rows[row], rows[pivot_row])]
                rhs[row] ^= rhs[pivot_row]
        pivot_columns.append(column)
        pivot_row += 1

    if any(not any(row) and value for row, value in zip(rows, rhs)):
        encoded = struct.pack("<Q", (1 << 64) - 1)
    else:
        free_columns = [column for column in range(m) if column not in pivot_columns]
        particular = 0
        for row, column in enumerate(pivot_columns):
            if rhs[row]:
                particular |= 1 << column
        words = [len(free_columns), particular]
        for free_column in free_columns:
            vector = 1 << free_column
            for row, pivot_column in enumerate(pivot_columns):
                if rows[row][free_column]:
                    vector |= 1 << pivot_column
            words.append(vector)
        encoded = b"".join(struct.pack("<Q", word) for word in words)

    effective_capacity = MAX_OUTPUT_BYTES if capacity is None else capacity
    if (type(output_is_null) is not bool or type(effective_capacity) is not int
            or effective_capacity < 0):
        return -2, b""
    if output_is_null or effective_capacity < len(encoded):
        return -2, b""
    return len(encoded), encoded
