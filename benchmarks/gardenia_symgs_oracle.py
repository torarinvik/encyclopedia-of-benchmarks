"""Independent bounded oracle for GARDENIA's sparse symmetric GS sweeps."""
from __future__ import annotations

import math

MAX_N = 8
MAX_NNZ = 64
MAX_INPUT_LENGTH = 5 + 4 * MAX_N + MAX_N + 2 * MAX_NNZ
MAX_OUTPUT_ELEMENTS = MAX_N


def _integer(value: float) -> bool:
    return math.isfinite(value) and value == math.trunc(value)


def expected_output(values, output_capacity=None, output_is_null=False,
                    input_is_null=False, input_length=None):
    if (not isinstance(values, (list, tuple))
            or type(output_is_null) is not bool or type(input_is_null) is not bool
            or (input_is_null and values)
            or (input_length is not None and
                (type(input_length) is not int or input_length != len(values)))
            or (output_capacity is not None and
                (type(output_capacity) is not int or output_capacity < 0))):
        return -1, []
    if input_is_null or len(values) < 3 or len(values) > MAX_INPUT_LENGTH:
        return -1, []
    try:
        data = [float(value) for value in values]
    except (TypeError, ValueError, OverflowError):
        return -1, []
    if any(type(value) not in (int, float) or not math.isfinite(x)
           for value, x in zip(values, data)):
        return -1, []
    if not all(_integer(data[i]) for i in range(3)):
        return -1, []
    n, nnz, colors = (int(data[i]) for i in range(3))
    if not (1 <= n <= MAX_N and 1 <= nnz <= MAX_NNZ and 1 <= colors <= n):
        return -1, []
    if len(data) != 5 + 4 * n + colors + 2 * nnz:
        return -1, []

    order_at = 3
    offsets_at = order_at + n
    row_at = offsets_at + colors + 1
    col_at = row_at + n + 1
    value_at = col_at + nnz
    x_at = value_at + nnz
    b_at = x_at + n

    def decode_ints(start, count, low, high):
        raw = data[start:start + count]
        if len(raw) != count or any(not _integer(value) or value < low or value > high
                                    for value in raw):
            return None
        return [int(value) for value in raw]

    order = decode_ints(order_at, n, 0, n - 1)
    offsets = decode_ints(offsets_at, colors + 1, 0, n)
    rows = decode_ints(row_at, n + 1, 0, nnz)
    cols = decode_ints(col_at, nnz, 0, n - 1)
    if order is None or offsets is None or rows is None or cols is None:
        return -1, []
    if sorted(order) != list(range(n)) or offsets[0] != 0 or offsets[-1] != n:
        return -1, []
    if any(a >= b for a, b in zip(offsets, offsets[1:])):
        return -1, []
    if rows[0] != 0 or rows[-1] != nnz or any(a > b for a, b in zip(rows, rows[1:])):
        return -1, []
    matrix = data[value_at:x_at]
    initial = data[x_at:b_at]
    rhs = data[b_at:b_at + n]
    if (len(matrix) != nnz or len(initial) != n or len(rhs) != n
            or any(abs(value) > 4 for value in matrix + initial + rhs)):
        return -1, []
    if any(any(cols[e] >= cols[e + 1] for e in range(rows[u], rows[u + 1] - 1))
           for u in range(n)):
        return -1, []

    group = [0] * n
    for color in range(colors):
        for pos in range(offsets[color], offsets[color + 1]):
            group[order[pos]] = color

    diagonal = [None] * n
    for u in range(n):
        row_entries = {cols[e]: matrix[e] for e in range(rows[u], rows[u + 1])}
        if u not in row_entries or row_entries[u] <= 0:
            return -1, []
        diagonal[u] = row_entries[u]
        if row_entries[u] <= sum(abs(value) for v, value in row_entries.items() if v != u):
            return -1, []
        for v, value in row_entries.items():
            if v != u and group[u] == group[v]:
                return -1, []
            other = {cols[e]: matrix[e] for e in range(rows[v], rows[v + 1])}
            if other.get(u) != value:
                return -1, []

    if output_is_null or (output_capacity is not None and output_capacity < n):
        return -2, []

    x = list(initial)
    for color in list(range(colors)) + list(range(colors - 1, -1, -1)):
        for pos in range(offsets[color], offsets[color + 1]):
            u = order[pos]
            rsum = 0.0
            diag = 0.0
            for e in range(rows[u], rows[u + 1]):
                v = cols[e]
                if u == v:
                    diag = matrix[e]
                else:
                    rsum += x[v] * matrix[e]
            if diag != 0.0:
                x[u] = (rhs[u] - rsum) / diag
    return n, x
