"""Independent dense exact-rational verifier for the bounded NAS BT profile."""
from __future__ import annotations

from collections.abc import Sequence
from fractions import Fraction

from npb_bt_5x5_block_tridiagonal_oracle import (
    BLOCK, INVALID_RESULT, _valid,
)


def expected_result(values: Sequence[int] | None, *, input_is_null: bool = False,
                    input_length: int | None = None) -> float:
    parsed = _valid(values, input_is_null, input_length)
    if parsed is None:
        return INVALID_RESULT
    n, lower, diagonal, upper, rhs = parsed
    size = n * BLOCK
    matrix = [[Fraction(0) for _ in range(size + 1)] for _ in range(size)]
    for block_row in range(n):
        for r in range(BLOCK):
            row = block_row * BLOCK + r
            for c in range(BLOCK):
                if block_row > 0:
                    matrix[row][(block_row - 1) * BLOCK + c] = Fraction(int(lower[block_row][r][c]))
                matrix[row][block_row * BLOCK + c] = Fraction(int(diagonal[block_row][r][c]))
                if block_row + 1 < n:
                    matrix[row][(block_row + 1) * BLOCK + c] = Fraction(int(upper[block_row][r][c]))
    # Correct the augmented column after coefficient assembly.
    for block_row in range(n):
        for r in range(BLOCK):
            matrix[block_row * BLOCK + r][size] = Fraction(int(rhs[block_row][r]))
    for pivot in range(size):
        best = max(range(pivot, size), key=lambda r: abs(matrix[r][pivot]))
        if matrix[best][pivot] == 0:
            return INVALID_RESULT
        matrix[pivot], matrix[best] = matrix[best], matrix[pivot]
        divisor = matrix[pivot][pivot]
        for c in range(pivot, size + 1):
            matrix[pivot][c] /= divisor
        for r in range(size):
            if r == pivot:
                continue
            factor = matrix[r][pivot]
            for c in range(pivot, size + 1):
                matrix[r][c] -= factor * matrix[pivot][c]
    return float(sum(Fraction(index + 1) * matrix[index][size]
                     for index in range(size)))
