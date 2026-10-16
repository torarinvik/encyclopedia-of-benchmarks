"""Oracle for bounded source-ordered, unnormalized Gram-Schmidt rows."""
import struct

MAX_ROWS = 4
MAX_DIMENSION = 4
MAX_INPUT_LENGTH = 2 + MAX_ROWS * MAX_DIMENSION
MAX_OUTPUT_BYTES = MAX_ROWS * MAX_DIMENSION * 8


def expected_output(values):
    if (not isinstance(values, (list, tuple)) or len(values) < 2
            or any(type(x) is not int or not -(2**63) <= x < 2**63 for x in values)):
        return -1, b""
    rows, dimension = values[:2]
    if not 1 <= rows <= MAX_ROWS or not rows <= dimension <= MAX_DIMENSION:
        return -1, b""
    if len(values) != 2 + rows * dimension:
        return -1, b""
    raw = values[2:]
    if any(x < -1000 or x > 1000 for x in raw):
        return -1, b""
    matrix = [[raw[i * dimension + j] / 1000.0 for j in range(dimension)]
              for i in range(rows)]
    for i in range(rows):
        if any(raw[i * dimension + j] != 0 for j in range(i)):
            return -1, b""
        if not 100 <= raw[i * dimension + i] <= 1000:
            return -1, b""
    orthogonal = [[0.0] * dimension for _ in range(rows)]
    for k in range(rows):
        if k == 0:
            orthogonal[0] = matrix[0][:]
            continue
        projections = [0.0] * dimension
        for previous in range(k):
            dot = 0.0
            norm = 0.0
            for j in range(dimension):
                dot += matrix[k][j] * orthogonal[previous][j]
                norm += orthogonal[previous][j] * orthogonal[previous][j]
            factor = dot / norm
            for j in range(dimension):
                projections[j] += orthogonal[previous][j] * factor
        for j in range(dimension):
            orthogonal[k][j] = matrix[k][j] - projections[j]
    result = [x for row in orthogonal for x in row]
    return len(result) * 8, struct.pack("<" + "d" * len(result), *result)
