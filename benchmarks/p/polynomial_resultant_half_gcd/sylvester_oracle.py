"""Independent small-case resultant via a Sylvester determinant."""
from .remainder_oracle import P, parse


def expected(values):
    parsed = parse(values)
    if parsed is None:
        return -1
    a, b = parsed
    m, n = len(a)-1, len(b)-1
    if m+n > 32:
        raise ValueError("determinant reference is restricted to small inputs")
    size = m+n
    if size == 0:
        return 1
    matrix = []
    for shift in range(n):
        row = [0]*size
        row[shift:shift+m+1] = reversed(a)
        matrix.append(row)
    for shift in range(m):
        row = [0]*size
        row[shift:shift+n+1] = reversed(b)
        matrix.append(row)
    result = 1
    for column in range(size):
        pivot = next((row for row in range(column, size) if matrix[row][column]), None)
        if pivot is None:
            return 0
        if pivot != column:
            matrix[pivot], matrix[column] = matrix[column], matrix[pivot]
            result = -result % P
        value = matrix[column][column]
        result = result * value % P
        inverse = pow(value, P-2, P)
        for row in range(column+1, size):
            factor = matrix[row][column] * inverse % P
            for j in range(column+1, size):
                matrix[row][j] = (matrix[row][j] - factor*matrix[column][j]) % P
    return result
