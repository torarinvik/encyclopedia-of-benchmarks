"""Independent pairwise-dominance oracle for Pareto row filtering."""

from __future__ import annotations

MAX_ROWS = 64
MAX_COLS = 8
MAX_INPUT_LENGTH = 2 + MAX_ROWS * MAX_COLS
OFFSET = 14695981039346656037
PRIME = 1099511628211
MASK64 = (1 << 64) - 1
MASK63 = (1 << 63) - 1


def expected_result(values: list[int] | tuple[int, ...]) -> int:
    if (not isinstance(values, (list, tuple)) or len(values) < 2
            or len(values) > MAX_INPUT_LENGTH
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63) for value in values)):
        return -1
    rows, cols = values[:2]
    if not 1 <= rows <= MAX_ROWS or not 1 <= cols <= MAX_COLS or len(values) != 2 + rows * cols:
        return -1
    cells = values[2:]
    if any(value < -1000 or value > 1000 for value in cells):
        return -1
    matrix = [cells[index * cols:(index + 1) * cols] for index in range(rows)]
    retained = []
    for index, row in enumerate(matrix):
        dominated = False
        for other_index, other in enumerate(matrix):
            if other_index == index:
                continue
            if all(left >= right for left, right in zip(other, row)) and (
                    any(left > right for left, right in zip(other, row)) or other_index < index):
                dominated = True
                break
        if not dominated:
            retained.append(row)
    words = [len(retained), cols, *(value for row in retained for value in row)]
    digest = OFFSET
    for word in words:
        bits = word & MASK64
        for shift in range(0, 64, 8):
            digest = ((digest ^ ((bits >> shift) & 0xFF)) * PRIME) & MASK64
    return digest & MASK63
