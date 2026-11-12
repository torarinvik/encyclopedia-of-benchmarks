"""Direct oracle for the bounded SPLASH-2 Ocean red-black smoother."""

from __future__ import annotations

from collections.abc import Sequence
import math

INVALID_RESULT = -1
OUTPUT_ERROR = -2
VALID_SIDES = (4, 6, 8)
MAX_CELLS = 64
MAX_INPUT_LENGTH = 132
MAX_OUTPUT_ELEMENTS = 65
ABSOLUTE_TOLERANCE = 1e-12
RELATIVE_TOLERANCE = 1e-12


def _number(value: object) -> bool:
    if type(value) not in (int, float):
        return False
    try:
        return math.isfinite(float(value))
    except OverflowError:
        return False


def _decode(values: Sequence[int | float] | None, input_length: int | None,
            input_is_null: bool) -> tuple[int, float, float, list[float], list[float]] | None:
    if input_is_null or not isinstance(values, (list, tuple)):
        return None
    length = len(values) if input_length is None else input_length
    if (type(length) is not int or length != len(values)
            or length < 3 or length > MAX_INPUT_LENGTH):
        return None
    if not all(_number(value) for value in values):
        return None
    side_value = float(values[0])
    if side_value not in tuple(float(side) for side in VALID_SIDES):
        return None
    side = int(side_value)
    cells = side * side
    if length != 3 + 2 * cells:
        return None
    eigenvalue_squared = float(values[1])
    spacing = float(values[2])
    if not 0.0 <= eigenvalue_squared <= 2.0 or not 0.125 <= spacing <= 1.0:
        return None
    factor = 4.0 - eigenvalue_squared * spacing * spacing
    if not math.isfinite(factor) or factor <= 0.0:
        return None
    grid = [float(value) for value in values[3:3 + cells]]
    rhs = [float(value) for value in values[3 + cells:]]
    if any(value < -8.0 or value > 8.0 for value in grid + rhs):
        return None
    return side, eigenvalue_squared, spacing, grid, rhs


def expected_output(values: Sequence[int | float] | None,
                    output_capacity: int | None = None,
                    output_is_null: bool = False,
                    input_length: int | None = None,
                    input_is_null: bool = False) -> tuple[int, list[float]]:
    """Apply one full red-then-black Gauss-Seidel sweep to the 2-D grid."""
    parsed = _decode(values, input_length, input_is_null)
    if parsed is None:
        return INVALID_RESULT, []
    side, eigenvalue_squared, spacing, grid, rhs = parsed
    needed = 1 + side * side
    if output_is_null or (output_capacity is not None and output_capacity < needed):
        return OUTPUT_ERROR, []

    factor = 4.0 - eigenvalue_squared * spacing * spacing
    max_change = 0.0
    for color in (0, 1):
        for row in range(1, side - 1):
            for column in range(1, side - 1):
                if (row + column) % 2 != color:
                    continue
                index = row * side + column
                neighbor_sum = (grid[index + 1] + grid[index - 1]
                                + grid[index - side] + grid[index + side])
                updated = (neighbor_sum - rhs[index]) / factor
                max_change = max(max_change, abs(grid[index] - updated))
                grid[index] = updated
    return needed, [max_change, *grid]
