"""Exact bounded oracle for integer matrices of order at most three."""

from __future__ import annotations

MAX_N = 3
MAX_VALUES = 1 + 2 * MAX_N * MAX_N


def _det3(matrix: list[int]) -> int:
    return (
        matrix[0] * (matrix[4] * matrix[8] - matrix[5] * matrix[7])
        - matrix[1] * (matrix[3] * matrix[8] - matrix[5] * matrix[6])
        + matrix[2] * (matrix[3] * matrix[7] - matrix[4] * matrix[6])
    )


def _charpoly(matrix: list[int], n: int) -> tuple[int, int, int]:
    trace = sum(matrix[i * n + i] for i in range(n))
    if n == 1:
        return -trace, 0, 0
    if n == 2:
        determinant = matrix[0] * matrix[3] - matrix[1] * matrix[2]
        return -trace, determinant, 0
    second = (
        matrix[0] * matrix[4] - matrix[1] * matrix[3]
        + matrix[0] * matrix[8] - matrix[2] * matrix[6]
        + matrix[4] * matrix[8] - matrix[5] * matrix[7]
    )
    return -trace, second, -_det3(matrix)


def _discriminant_cubic(a: int, b: int, c: int) -> int:
    return a * a * b * b - 4 * b**3 - 4 * a**3 * c - 27 * c * c + 18 * a * b * c


def _rank_singular(matrix: list[int], n: int) -> int:
    """Rank of a known-singular n-by-n integer matrix, for n <= 3."""
    for r0 in range(n):
        for r1 in range(r0 + 1, n):
            for c0 in range(n):
                for c1 in range(c0 + 1, n):
                    minor = matrix[r0 * n + c0] * matrix[r1 * n + c1] - matrix[r0 * n + c1] * matrix[r1 * n + c0]
                    if minor != 0:
                        return 2
    return 1 if any(matrix) else 0


def _shifted(matrix: list[int], n: int, numerator: int, denominator: int) -> list[int]:
    result = [denominator * value for value in matrix]
    for i in range(n):
        result[i * n + i] -= numerator
    return result


def _multiply(a: list[int], b: list[int], n: int) -> list[int]:
    return [
        sum(a[row * n + k] * b[k * n + col] for k in range(n))
        for row in range(n)
        for col in range(n)
    ]


def _similar(a: list[int], b: list[int], n: int) -> bool:
    coeffs = _charpoly(a, n)
    if coeffs != _charpoly(b, n):
        return False
    if n == 1:
        return True
    ca, cb, cc = coeffs
    if n == 2:
        if ca * ca - 4 * cb != 0:
            return True
        da = _shifted(a, n, -ca, 2)
        db = _shifted(b, n, -ca, 2)
        return _rank_singular(da, n) == _rank_singular(db, n)

    if _discriminant_cubic(ca, cb, cc) != 0:
        return True
    q = ca * ca - 3 * cb
    if q == 0:
        # The only eigenvalue is -ca/3; compare nullities of D and D^2.
        da = _shifted(a, n, -ca, 3)
        db = _shifted(b, n, -ca, 3)
        if _rank_singular(da, n) != _rank_singular(db, n):
            return False
        return _rank_singular(_multiply(da, da, n), n) == _rank_singular(_multiply(db, db, n), n)

    # For a cubic with one repeated root, lambda=(9c-a*b)/(2*(a^2-3b)).
    numerator = 9 * cc - ca * cb
    denominator = 2 * q
    da = _shifted(a, n, numerator, denominator)
    db = _shifted(b, n, numerator, denominator)
    return _rank_singular(da, n) == _rank_singular(db, n)


def expected_result(values: list[int] | tuple[int, ...]) -> int:
    if not isinstance(values, (list, tuple)) or not 1 <= len(values) <= MAX_VALUES:
        return -1
    if any(type(value) is not int or not -(1 << 63) <= value < (1 << 63) for value in values):
        return -1
    n = values[0]
    if not 1 <= n <= MAX_N or len(values) != 1 + 2 * n * n:
        return -1
    entries = values[1:]
    if any(not -5 <= value <= 5 for value in entries):
        return -1
    matrix_size = n * n
    return int(_similar(list(entries[:matrix_size]), list(entries[matrix_size:]), n))
