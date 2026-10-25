"""Independent reference for the bounded miniAMR stencil branches."""
from __future__ import annotations

from collections.abc import Sequence

INVALID_RESULT = -1e300
MIN_DIMENSION = 2
MAX_DIMENSION = 4
MIN_VALUE = -1000
MAX_VALUE = 1000
MIN_INPUT_LENGTH = 68
MAX_INPUT_LENGTH = 220


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
    if not MIN_INPUT_LENGTH <= len(values) <= MAX_INPUT_LENGTH:
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

    stencil, nx, ny, nz = values[:4]
    if stencil not in (7, 27):
        return INVALID_RESULT
    if any(
        type(dimension) is not int
        or dimension < MIN_DIMENSION
        or dimension > MAX_DIMENSION
        or dimension % 2 != 0
        for dimension in (nx, ny, nz)
    ):
        return INVALID_RESULT
    if len(values) != 4 + (nx + 2) * (ny + 2) * (nz + 2):
        return INVALID_RESULT
    grid = values[4:]
    if any(value < MIN_VALUE or value > MAX_VALUE for value in grid):
        return INVALID_RESULT

    # miniAMR stores a block as array[i][j][k], so k is contiguous. This
    # oracle builds the row-major offset directly and keeps the two source
    # stencil branches separate.
    stride_i = (ny + 2) * (nz + 2)
    stride_j = nz + 2

    def at(i: int, j: int, k: int) -> float:
        return float(grid[i * stride_i + j * stride_j + k])

    staged: list[float] = []
    for i in range(1, nx + 1):
        for j in range(1, ny + 1):
            for k in range(1, nz + 1):
                if stencil == 7:
                    total = (
                        at(i - 1, j, k)
                        + at(i, j - 1, k)
                        + at(i, j, k - 1)
                        + at(i, j, k)
                        + at(i, j, k + 1)
                        + at(i, j + 1, k)
                        + at(i + 1, j, k)
                    )
                    staged.append(total / 7.0)
                else:
                    back = (
                        at(i - 1, j - 1, k - 1)
                        + at(i - 1, j - 1, k)
                        + at(i - 1, j - 1, k + 1)
                        + at(i - 1, j, k - 1)
                        + at(i - 1, j, k)
                        + at(i - 1, j, k + 1)
                        + at(i - 1, j + 1, k - 1)
                        + at(i - 1, j + 1, k)
                        + at(i - 1, j + 1, k + 1)
                    )
                    middle = (
                        at(i, j - 1, k - 1)
                        + at(i, j - 1, k)
                        + at(i, j - 1, k + 1)
                        + at(i, j, k - 1)
                        + at(i, j, k)
                        + at(i, j, k + 1)
                        + at(i, j + 1, k - 1)
                        + at(i, j + 1, k)
                        + at(i, j + 1, k + 1)
                    )
                    front = (
                        at(i + 1, j - 1, k - 1)
                        + at(i + 1, j - 1, k)
                        + at(i + 1, j - 1, k + 1)
                        + at(i + 1, j, k - 1)
                        + at(i + 1, j, k)
                        + at(i + 1, j, k + 1)
                        + at(i + 1, j + 1, k - 1)
                        + at(i + 1, j + 1, k)
                        + at(i + 1, j + 1, k + 1)
                    )
                    staged.append((back + middle + front) / 27.0)

    # The package returns a scalar projection after all cell values have been
    # staged, matching miniAMR's compute-then-copy update semantics.
    checksum = 0.0
    for q, value in enumerate(staged):
        checksum += float(q + 1) * value * value
    return checksum
