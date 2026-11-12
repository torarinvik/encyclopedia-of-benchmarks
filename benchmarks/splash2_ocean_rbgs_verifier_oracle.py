"""Independent matrix-based checker for the Ocean red-black sweep."""

from __future__ import annotations

from collections.abc import Sequence
import math

INVALID_RESULT = -1
OUTPUT_ERROR = -2
MAX_INPUT_LENGTH = 132


def expected_output(values: Sequence[int | float] | None,
                    output_capacity: int | None = None,
                    output_is_null: bool = False,
                    input_length: int | None = None,
                    input_is_null: bool = False) -> tuple[int, list[float]]:
    if input_is_null or not isinstance(values, (list, tuple)):
        return INVALID_RESULT, []
    actual_length = len(values) if input_length is None else input_length
    if (type(actual_length) is not int or actual_length != len(values)
            or actual_length < 3 or actual_length > MAX_INPUT_LENGTH):
        return INVALID_RESULT, []
    for value in values:
        if type(value) not in (int, float):
            return INVALID_RESULT, []
        try:
            if not math.isfinite(float(value)):
                return INVALID_RESULT, []
        except OverflowError:
            return INVALID_RESULT, []
    side_value, eigenvalue_squared, spacing = map(float, values[:3])
    if side_value not in (4.0, 6.0, 8.0):
        return INVALID_RESULT, []
    side = int(side_value)
    cell_count = side * side
    if actual_length != 3 + 2 * cell_count:
        return INVALID_RESULT, []
    if not 0.0 <= eigenvalue_squared <= 2.0 or not 0.125 <= spacing <= 1.0:
        return INVALID_RESULT, []

    grid_values = [float(value) for value in values[3:3 + cell_count]]
    rhs_values = [float(value) for value in values[3 + cell_count:]]
    if any(not -8.0 <= value <= 8.0 for value in grid_values + rhs_values):
        return INVALID_RESULT, []
    grid = [grid_values[row * side:(row + 1) * side] for row in range(side)]
    rhs = [rhs_values[row * side:(row + 1) * side] for row in range(side)]
    factor = 4.0 - eigenvalue_squared * spacing * spacing
    if not math.isfinite(factor) or factor <= 0.0:
        return INVALID_RESULT, []

    largest_update = 0.0
    for target_color in (0, 1):
        for row in range(1, side - 1):
            for column in range(1, side - 1):
                if ((row + column) & 1) != target_color:
                    continue
                old_value = grid[row][column]
                new_value = (
                    grid[row][column + 1] + grid[row][column - 1]
                    + grid[row - 1][column] + grid[row + 1][column]
                    - rhs[row][column]
                ) / factor
                grid[row][column] = new_value
                update_size = abs(old_value - new_value)
                if update_size > largest_update:
                    largest_update = update_size

    output = [largest_update]
    for row in grid:
        output.extend(row)
    required = 1 + cell_count
    if output_is_null or (output_capacity is not None and output_capacity < required):
        return OUTPUT_ERROR, []
    return required, output
