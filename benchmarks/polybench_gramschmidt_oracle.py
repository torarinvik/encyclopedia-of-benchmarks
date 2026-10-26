"""Independent bounded oracle for the PolyBench modified Gram-Schmidt QR kernel."""

import math

MAX_M = 6
MAX_N = 6
MAX_INPUT_LENGTH = 2
MAX_OUTPUT_ELEMENTS = 72
INVALID_RESULT = -1
OUTPUT_ERROR = -2


def _integer_dimension(value):
    if isinstance(value, bool):
        return False
    if isinstance(value, int):
        return True
    return isinstance(value, float) and math.isfinite(value) and value.is_integer()


def expected_output(values):
    if values is None or len(values) != MAX_INPUT_LENGTH:
        return INVALID_RESULT, []
    raw_m, raw_n = values
    if not _integer_dimension(raw_m) or not _integer_dimension(raw_n):
        return INVALID_RESULT, []
    m, n = int(raw_m), int(raw_n)
    if not (1 <= n <= m <= MAX_M and n <= MAX_N):
        return INVALID_RESULT, []

    a = [[0.0] * n for _ in range(m)]
    q = [[0.0] * n for _ in range(m)]
    r = [[0.0] * n for _ in range(n)]
    for i in range(m):
        for j in range(n):
            a[i][j] = (((i * j) % m) / m * 100.0) + 10.0

    for k in range(n):
        norm_squared = 0.0
        for i in range(m):
            norm_squared += a[i][k] * a[i][k]
        r[k][k] = math.sqrt(norm_squared)
        if r[k][k] == 0.0 or not math.isfinite(r[k][k]):
            return INVALID_RESULT, []
        for i in range(m):
            q[i][k] = a[i][k] / r[k][k]
        for j in range(k + 1, n):
            r[k][j] = 0.0
            for i in range(m):
                r[k][j] += q[i][k] * a[i][j]
            for i in range(m):
                a[i][j] = a[i][j] - q[i][k] * r[k][j]

    return n * n + m * n, [value for row in r for value in row] + [value for row in q for value in row]


def abi_result(values, output_capacity=None, output_is_null=False, input_is_null=False):
    if input_is_null:
        return INVALID_RESULT, []
    result, output = expected_output(values)
    if result < 0:
        return result, []
    if output_is_null or output_capacity is not None and output_capacity < result:
        return OUTPUT_ERROR, []
    return result, output
