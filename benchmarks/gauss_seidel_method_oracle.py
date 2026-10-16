"""Exact rational oracle for bounded Gauss-Seidel systems."""
from fractions import Fraction
import struct

MAX_DIMENSION = 8
MAX_ENTRY_MICRO = 1_000_000_000


def expected_output(values, capacity=None):
    if not isinstance(values, (list, tuple)) or not values or any(type(v) is not int for v in values):
        return -1, b""
    n = values[0]
    if not 1 <= n <= MAX_DIMENSION or len(values) != 1 + n*n + n:
        return -1, b""
    packed = values[1:]
    if any(abs(v) > MAX_ENTRY_MICRO for v in packed):
        return -1, b""
    a = [packed[r*n:(r+1)*n] for r in range(n)]
    b = packed[n*n:]
    for r in range(n):
        if a[r][r] <= 0 or any(a[r][c] != a[c][r] for c in range(n)):
            return -1, b""
        if a[r][r] <= sum(abs(a[r][c]) for c in range(n) if c != r):
            return -1, b""
    m = [[Fraction(a[r][c]) for c in range(n)] + [Fraction(b[r])] for r in range(n)]
    for p in range(n):
        d = m[p][p]
        for c in range(p, n + 1):
            m[p][c] /= d
        for r in range(n):
            if r != p:
                f = m[r][p]
                for c in range(p, n + 1):
                    m[r][c] -= f*m[p][c]
    result = struct.pack("<" + "d"*n, *(round(float(m[i][n]), 10) for i in range(n)))
    if capacity is not None:
        if capacity < len(result):
            return -2, b""
    return len(result), result
