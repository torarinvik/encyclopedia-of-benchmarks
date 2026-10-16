"""Exact small-integer oracle for the five-point conic determinants."""

from __future__ import annotations

from itertools import permutations
import struct

I64_MIN, I64_MAX = -(2**63), 2**63 - 1
MAX_INPUT_LENGTH = 11  # includes an overlong malformed workload input
MAX_ABS_COORDINATE = 10
COLUMN_MAPS = (
    (1, 2, 3, 4, 5),
    (0, 2, 3, 4, 5),
    (0, 1, 3, 4, 5),
    (0, 1, 2, 4, 5),
    (0, 1, 2, 3, 5),
    (0, 1, 2, 3, 4),
)
COEFFICIENT_SIGNS = (1, -1, 1, -1, 1, -1)
PERMUTATIONS = tuple(permutations(range(5)))


def determinant(matrix: list[list[int]]) -> int:
    """Evaluate a 5x5 determinant by its 120 signed products."""
    total = 0
    for permutation in PERMUTATIONS:
        inversions = sum(
            permutation[left] > permutation[right]
            for left in range(5) for right in range(left + 1, 5)
        )
        product = 1
        for row, column in enumerate(permutation):
            product *= matrix[row][column]
        total += -product if inversions % 2 else product
    return total


def expected_output(values: list[int]) -> tuple[int, bytes]:
    if (not isinstance(values, list) or len(values) != 10
            or any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values)
            or any(not -MAX_ABS_COORDINATE <= value <= MAX_ABS_COORDINATE for value in values)):
        return -2, b""
    features = []
    for offset in range(0, 10, 2):
        x, y = values[offset:offset + 2]
        features.append((x * x, x * y, y * y, x, y, 1))
    coefficients = []
    for columns, sign in zip(COLUMN_MAPS, COEFFICIENT_SIGNS):
        matrix = [[row[column] for column in columns] for row in features]
        coefficients.append(sign * determinant(matrix))
    return 6, b"".join(struct.pack("<q", coefficient) for coefficient in coefficients)
