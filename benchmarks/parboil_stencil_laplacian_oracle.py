"""Independent oracle for Parboil's bounded seven-point Laplacian profile."""

from __future__ import annotations

import math
import struct
from collections.abc import Sequence

MIN_DIMENSION = 3
MAX_DIMENSION = 5
MAX_STEPS = 4
MAX_CELLS = MAX_DIMENSION ** 3
MAX_INPUT_LENGTH = 4 + MAX_CELLS
MAX_OUTPUT_ELEMENTS = MAX_CELLS
WORKSPACE_ELEMENTS = 3 * MAX_CELLS
MIN_GRID_VALUE = -8.0
MAX_GRID_VALUE = 8.0
INVALID_RESULT = -1
OUTPUT_ERROR = -2
ABSOLUTE_TOLERANCE = 1e-6
RELATIVE_TOLERANCE = 1e-6


def _f32(value: float) -> float:
    return struct.unpack("<f", struct.pack("<f", float(value)))[0]


def _header_and_grid(values: Sequence[int | float]):
    if not isinstance(values, (list, tuple)) or len(values) < 4 or len(values) > MAX_INPUT_LENGTH:
        return None
    if any(type(value) not in (int, float) or not math.isfinite(float(value)) for value in values):
        return None
    dims_steps = values[:4]
    if any(float(value) != math.trunc(float(value)) for value in dims_steps):
        return None
    nx, ny, nz, steps = (int(value) for value in dims_steps)
    if (not MIN_DIMENSION <= nx <= MAX_DIMENSION
            or not MIN_DIMENSION <= ny <= MAX_DIMENSION
            or not MIN_DIMENSION <= nz <= MAX_DIMENSION
            or not 1 <= steps <= MAX_STEPS):
        return None
    cells = nx * ny * nz
    if len(values) != 4 + cells:
        return None
    grid = []
    for value in values[4:]:
        number = float(value)
        if not MIN_GRID_VALUE <= number <= MAX_GRID_VALUE:
            return None
        grid.append(_f32(number))
    return nx, ny, nz, steps, grid


def expected_output(values: Sequence[int | float]) -> list[float] | None:
    """Return the final x-fast grid, with each source operation rounded to f32."""
    parsed = _header_and_grid(values)
    if parsed is None:
        return None
    nx, ny, nz, steps, initial = parsed
    a = initial[:]
    b = initial[:]
    c0 = _f32(_f32(1.0) / _f32(6.0))
    c1 = _f32(_f32(_f32(1.0) / _f32(6.0)) / _f32(6.0))

    def index(i: int, j: int, k: int) -> int:
        return i + nx * (j + ny * k)

    for _ in range(steps):
        for i in range(1, nx - 1):
            for j in range(1, ny - 1):
                for k in range(1, nz - 1):
                    q = index(i, j, k)
                    neighbor_sum = _f32(a[index(i, j, k + 1)] + a[index(i, j, k - 1)])
                    neighbor_sum = _f32(neighbor_sum + a[index(i, j + 1, k)])
                    neighbor_sum = _f32(neighbor_sum + a[index(i, j - 1, k)])
                    neighbor_sum = _f32(neighbor_sum + a[index(i + 1, j, k)])
                    neighbor_sum = _f32(neighbor_sum + a[index(i - 1, j, k)])
                    neighbor_term = _f32(neighbor_sum * c1)
                    center_term = _f32(a[q] * c0)
                    b[q] = _f32(neighbor_term - center_term)
        a, b = b, a
    return [float(value) for value in a]


def abi_expected_output(values: Sequence[int | float], output_capacity: int | None = None,
                        output_is_null: bool = False, input_is_null: bool = False,
                        input_length: int | None = None) -> tuple[int, list[float]]:
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or input_is_null or not isinstance(values, (list, tuple))):
        return INVALID_RESULT, []
    if (input_length is not None
            and (type(input_length) is not int or input_length != len(values))):
        return INVALID_RESULT, []
    output = expected_output(values)
    if output is None:
        return INVALID_RESULT, []
    if (output_capacity is not None
            and (type(output_capacity) is not int or output_capacity < 0)):
        return INVALID_RESULT, []
    if output_is_null or output_capacity is not None and output_capacity < len(output):
        return OUTPUT_ERROR, []
    return len(output), output
