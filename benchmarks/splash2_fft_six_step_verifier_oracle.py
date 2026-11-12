"""Independent six-step matrix-form oracle; row transforms use direct sums."""

from __future__ import annotations

from collections.abc import Sequence
import math

INVALID_RESULT = -1
OUTPUT_ERROR = -2
MAX_INPUT_LENGTH = 130
TAU = 2.0 * math.pi


def _finite(value: object) -> bool:
    if type(value) not in (int, float):
        return False
    try:
        return math.isfinite(float(value))
    except OverflowError:
        return False


def expected_output(values: Sequence[int | float] | None,
                    output_capacity: int | None = None,
                    output_is_null: bool = False,
                    input_length: int | None = None,
                    input_is_null: bool = False) -> tuple[int, list[float]]:
    """Validate independently, then factor the DFT into direct row transforms."""
    if input_is_null or not isinstance(values, (list, tuple)):
        return INVALID_RESULT, []
    length = len(values) if input_length is None else input_length
    if (type(length) is not int or length != len(values)
            or length < 9 or length > MAX_INPUT_LENGTH):
        return INVALID_RESULT, []
    if not all(_finite(value) for value in values):
        return INVALID_RESULT, []
    side_number = float(values[0])
    if side_number not in (2.0, 4.0, 8.0):
        return INVALID_RESULT, []
    side = int(side_number)
    points = side * side
    if length != 1 + 2 * points:
        return INVALID_RESULT, []

    matrix: list[list[complex]] = []
    for row_index in range(side):
        row: list[complex] = []
        for column in range(side):
            index = 1 + 2 * (row_index * side + column)
            real, imag = float(values[index]), float(values[index + 1])
            if real < -8.0 or real > 8.0 or imag < -8.0 or imag > 8.0:
                return INVALID_RESULT, []
            row.append(complex(real, imag))
        matrix.append(row)

    def direct_rows(rows: list[list[complex]]) -> list[list[complex]]:
        transformed_rows: list[list[complex]] = []
        for row in rows:
            transformed: list[complex] = []
            for frequency in range(side):
                total = 0j
                for sample_index in range(side):
                    phase = -TAU * sample_index * frequency / side
                    total += row[sample_index] * complex(math.cos(phase), math.sin(phase))
                transformed.append(total)
            transformed_rows.append(transformed)
        return transformed_rows

    first_transpose = [[matrix[row][column] for row in range(side)]
                       for column in range(side)]
    first_rows = direct_rows(first_transpose)
    total_points = side * side
    for row in range(side):
        for column in range(side):
            phase = -TAU * row * column / total_points
            first_rows[row][column] *= complex(math.cos(phase), math.sin(phase))
    second_transpose = [[first_rows[row][column] for row in range(side)]
                        for column in range(side)]
    second_rows = direct_rows(second_transpose)
    output_matrix = [[second_rows[row][column] for row in range(side)]
                     for column in range(side)]
    flattened: list[float] = []
    for row in output_matrix:
        for value in row:
            flattened.extend((value.real, value.imag))

    needed = 2 * total_points
    if output_is_null or (output_capacity is not None and output_capacity < needed):
        return OUTPUT_ERROR, []
    return needed, flattened
