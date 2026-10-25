"""Independent oracle for the bounded miniGMG cell-centered restriction."""
from __future__ import annotations

from collections.abc import Sequence

INVALID_RESULT = -1e300
MIN_DIMENSION = 2
MAX_DIMENSION = 8
MIN_VALUE = -32768
MAX_VALUE = 32767
MAX_INPUT_LENGTH = 3 + MAX_DIMENSION**3


def expected_result(
    values: Sequence[int] | None,
    *,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> float:
    if (
        type(input_is_null) is not bool
        or input_is_null
        or values is None
        or not isinstance(values, (list, tuple))
    ):
        return INVALID_RESULT
    if not 11 <= len(values) <= MAX_INPUT_LENGTH:
        return INVALID_RESULT
    if input_length is not None and (
        type(input_length) is not int or input_length != len(values)
    ):
        return INVALID_RESULT
    if any(
        type(value) is not int or not -(1 << 63) <= value < (1 << 63)
        for value in values
    ):
        return INVALID_RESULT

    nx, ny, nz = values[:3]
    if any(
        type(dimension) is not int
        or dimension < MIN_DIMENSION
        or dimension > MAX_DIMENSION
        or dimension % 2 != 0
        for dimension in (nx, ny, nz)
    ):
        return INVALID_RESULT
    if len(values) != 3 + nx * ny * nz:
        return INVALID_RESULT
    fine = values[3:]
    if any(value < MIN_VALUE or value > MAX_VALUE for value in fine):
        return INVALID_RESULT

    # The independently expressed 3-D indexing below follows a flat row-major
    # fine grid, with x varying fastest.  The source operator visits coarse
    # cells in the same k, j, i order and averages the corresponding 2-cube.
    coarse_nx, coarse_ny, coarse_nz = nx // 2, ny // 2, nz // 2
    plane = nx * ny
    checksum = 0.0
    coarse_index = 0
    for ck in range(coarse_nz):
        for cj in range(coarse_ny):
            for ci in range(coarse_nx):
                x = 2 * ci
                y = 2 * cj
                z = 2 * ck
                start = x + y * nx + z * plane
                total = (
                    float(fine[start])
                    + float(fine[start + 1])
                    + float(fine[start + nx])
                    + float(fine[start + nx + 1])
                    + float(fine[start + plane])
                    + float(fine[start + plane + 1])
                    + float(fine[start + plane + nx])
                    + float(fine[start + plane + nx + 1])
                )
                average = total / 8.0
                ordinal_weight = float(coarse_index + 1)
                checksum += ordinal_weight * (average * average)
                coarse_index += 1
    return checksum
