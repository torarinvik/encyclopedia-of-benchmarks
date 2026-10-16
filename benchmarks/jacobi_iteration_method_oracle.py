"""Runtime oracle for bounded, source-ordered Jacobi iterations."""
import struct

MAX_DIMENSION = 4
MAX_ITERATIONS = 8
MAX_INPUT_LENGTH = 2 + MAX_DIMENSION * MAX_DIMENSION + 2 * MAX_DIMENSION
MAX_OUTPUT_BYTES = MAX_DIMENSION * 8
I64_MIN = -(2**63)
I64_MAX = 2**63 - 1


def expected_output(values):
    if (not isinstance(values, (list, tuple)) or len(values) < 2
            or any(type(x) is not int or not -(2**63) <= x < 2**63 for x in values)):
        return -1, b""
    n, iterations = values[:2]
    if not 2 <= n <= MAX_DIMENSION or not 1 <= iterations <= MAX_ITERATIONS:
        return -1, b""
    if len(values) != 2 + n * n + 2 * n:
        return -1, b""
    matrix_raw = values[2:2 + n * n]
    rhs_raw = values[2 + n * n:2 + n * n + n]
    initial_raw = values[2 + n * n + n:]
    if any(not 0 <= x <= 4000 for x in matrix_raw):
        return -1, b""
    if any(not -2000 <= x <= 2000 for x in rhs_raw + initial_raw):
        return -1, b""
    matrix = [[matrix_raw[i * n + j] / 1000.0 for j in range(n)] for i in range(n)]
    for i in range(n):
        if matrix[i][i] <= sum(matrix[i][j] for j in range(n) if j != i):
            return -1, b""
    rhs = [x / 1000.0 for x in rhs_raw]
    current = [x / 1000.0 for x in initial_raw]
    for _ in range(iterations):
        updated = []
        for i in range(n):
            total = 0.0
            for j in range(n):
                if i != j:
                    total += -matrix[i][j] * current[j]
            updated.append((total + rhs[i]) / matrix[i][i])
        current = updated
    return n * 8, struct.pack("<" + "d" * n, *current)
