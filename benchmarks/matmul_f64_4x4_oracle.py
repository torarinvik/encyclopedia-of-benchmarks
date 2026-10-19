"""Independent numeric oracle for the bounded 4x4 matrix multiplication."""
from __future__ import annotations

MIN_ITERATIONS = 1
MAX_ITERATIONS = 10_000
MAX_PARSEABLE_INPUT_LENGTH = 2
MATRIX_ELEMENTS = 16
INVALID_RESULT = -1
OUTPUT_ERROR = -2

_A = (
    (4.5, 1.3, 6.0, 4.1),
    (2.5, 7.2, 7.7, 1.7),
    (6.7, 1.3, 9.4, 1.3),
    (1.1, 2.2, 3.0, 2.1),
)
_B = (
    (1.0, 7.9, 5.1, 3.4),
    (6.6, 2.8, 5.4, 9.2),
    (5.0, 4.1, 4.1, 9.9),
    (8.4, 3.7, 9.5, 6.4),
)


def expected_output(iteration_count: list[float]) -> tuple[int, list[float]]:
    """Return A×B in row-major order, or invalid-input status."""
    if (type(iteration_count) is not list or len(iteration_count) != 1
            or type(iteration_count[0]) not in (int, float)):
        return INVALID_RESULT, []
    requested = float(iteration_count[0])
    if (not requested.is_integer()
            or not MIN_ITERATIONS <= requested <= MAX_ITERATIONS):
        return INVALID_RESULT, []
    result: list[float] = []
    for row in range(4):
        for column in range(4):
            total = _A[row][0] * _B[0][column]
            total += _A[row][1] * _B[1][column]
            total += _A[row][2] * _B[2][column]
            total += _A[row][3] * _B[3][column]
            result.append(total)
    return MATRIX_ELEMENTS, result
