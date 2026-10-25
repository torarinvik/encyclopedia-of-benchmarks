"""Independent oracle for the bounded TSVC s257 matrix/scalar recurrence."""

from __future__ import annotations

from collections.abc import Sequence

MIN_N = 2
MAX_N = 8
MAX_PASSES = 4
MAX_INPUT_LENGTH = 2 + MAX_N + 2 * MAX_N * MAX_N
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1


def expected_result(values: Sequence[int] | None, input_length: int | None = None) -> int:
    """Return the final sum of A and AA, or -1 when the frame is invalid."""
    if values is None or not isinstance(values, (list, tuple)):
        return -1
    if input_length is not None and (
        type(input_length) is not int or input_length != len(values)
    ):
        return -1
    if not 12 <= len(values) <= MAX_INPUT_LENGTH:
        return -1
    if any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values):
        return -1

    n, passes = values[:2]
    if not MIN_N <= n <= MAX_N or not 1 <= passes <= MAX_PASSES:
        return -1
    if len(values) != 2 + n + 2 * n * n:
        return -1
    if any(value not in (-1, 0, 1) for value in values[2:]):
        return -1

    a = list(values[2:2 + n])
    matrix_size = n * n
    aa_start = 2 + n
    aa_flat = values[aa_start:aa_start + matrix_size]
    bb_flat = values[aa_start + matrix_size:]
    aa = [list(aa_flat[row * n:(row + 1) * n]) for row in range(n)]
    bb = [list(bb_flat[row * n:(row + 1) * n]) for row in range(n)]

    for _ in range(passes):
        for column in range(1, n):
            previous = a[column - 1]
            for row in range(n):
                updated = aa[row][column] - previous
                a[column] = updated
                aa[row][column] = updated + bb[row][column]

    return sum(a) + sum(sum(row) for row in aa)
