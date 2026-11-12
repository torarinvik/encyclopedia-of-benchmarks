"""Primary block-Thomas oracle for the bounded NAS BT block sweep."""
from __future__ import annotations

from collections.abc import Sequence

BLOCK = 5
MAX_LINE = 4
INVALID_RESULT = -1e300
ROW_SIZE = 80
MAX_INPUT_LENGTH = 1 + ROW_SIZE * MAX_LINE


def _valid(values: Sequence[int] | None, input_is_null: bool,
           input_length: int | None) -> tuple[int, list[list[list[float]]],
                                               list[list[list[float]]],
                                               list[list[list[float]]],
                                               list[list[float]]] | None:
    if input_is_null or values is None or not isinstance(values, (list, tuple)):
        return None
    if not 1 <= len(values) <= MAX_INPUT_LENGTH:
        return None
    if input_length is not None and input_length != len(values):
        return None
    if any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
           for value in values):
        return None
    n = values[0]
    if not 2 <= n <= MAX_LINE or len(values) != 1 + ROW_SIZE * n:
        return None

    lower = [[[0.0] * BLOCK for _ in range(BLOCK)] for _ in range(n)]
    diagonal = [[[0.0] * BLOCK for _ in range(BLOCK)] for _ in range(n)]
    upper = [[[0.0] * BLOCK for _ in range(BLOCK)] for _ in range(n)]
    rhs = [[0.0] * BLOCK for _ in range(n)]
    for row in range(n):
        cursor = 1 + ROW_SIZE * row
        for matrix in (lower[row], diagonal[row], upper[row]):
            for r in range(BLOCK):
                for c in range(BLOCK):
                    value = values[cursor]
                    cursor += 1
                    if matrix is diagonal[row]:
                        if r == c:
                            if not 40 <= value <= 64:
                                return None
                        elif not -2 <= value <= 2:
                            return None
                    elif not -2 <= value <= 2:
                        return None
                    matrix[r][c] = float(value)
        for r in range(BLOCK):
            value = values[cursor]
            cursor += 1
            if not -1000 <= value <= 1000:
                return None
            rhs[row][r] = float(value)
        if row == 0 and any(v != 0.0 for line in lower[row] for v in line):
            return None
        if row == n - 1 and any(v != 0.0 for line in upper[row] for v in line):
            return None
        for r in range(BLOCK):
            off_diagonal = sum(abs(diagonal[row][r][c]) for c in range(BLOCK) if c != r)
            off_diagonal += sum(abs(lower[row][r][c]) + abs(upper[row][r][c])
                                for c in range(BLOCK))
            if diagonal[row][r][r] <= off_diagonal:
                return None
    return n, lower, diagonal, upper, rhs


def _solve5(matrix: list[list[float]], right: list[list[float]]) -> list[list[float]] | None:
    """Partial-pivot 5x5 elimination with six simultaneous right-hand sides."""
    augmented = [matrix[r][:] + right[r][:] for r in range(BLOCK)]
    width = BLOCK + 6
    for pivot in range(BLOCK):
        best = max(range(pivot, BLOCK), key=lambda r: abs(augmented[r][pivot]))
        if augmented[best][pivot] == 0.0:
            return None
        augmented[pivot], augmented[best] = augmented[best], augmented[pivot]
        scale = augmented[pivot][pivot]
        for c in range(pivot, width):
            augmented[pivot][c] /= scale
        for r in range(BLOCK):
            if r == pivot:
                continue
            scale = augmented[r][pivot]
            for c in range(pivot, width):
                augmented[r][c] -= scale * augmented[pivot][c]
    return [row[BLOCK:] for row in augmented]


def expected_result(values: Sequence[int] | None, *, input_is_null: bool = False,
                    input_length: int | None = None) -> float:
    parsed = _valid(values, input_is_null, input_length)
    if parsed is None:
        return INVALID_RESULT
    n, lower, diagonal, upper, rhs = parsed
    modified_upper: list[list[list[float]]] = []
    modified_rhs: list[list[float]] = []
    for row in range(n):
        schur = [line[:] for line in diagonal[row]]
        reduced = rhs[row][:]
        if row:
            for r in range(BLOCK):
                for c in range(BLOCK):
                    schur[r][c] -= sum(lower[row][r][k] * modified_upper[row - 1][k][c]
                                       for k in range(BLOCK))
                reduced[r] -= sum(lower[row][r][k] * modified_rhs[row - 1][k]
                                  for k in range(BLOCK))
        right = [[upper[row][r][c] for c in range(BLOCK)] + [reduced[r]]
                 for r in range(BLOCK)]
        solved = _solve5(schur, right)
        if solved is None:
            return INVALID_RESULT
        modified_upper.append([line[:BLOCK] for line in solved])
        modified_rhs.append([line[BLOCK] for line in solved])

    solution = [[0.0] * BLOCK for _ in range(n)]
    solution[-1] = modified_rhs[-1][:]
    for row in range(n - 2, -1, -1):
        for r in range(BLOCK):
            solution[row][r] = modified_rhs[row][r] - sum(
                modified_upper[row][r][c] * solution[row + 1][c]
                for c in range(BLOCK)
            )
    return sum((row * BLOCK + r + 1) * solution[row][r]
               for row in range(n) for r in range(BLOCK))
