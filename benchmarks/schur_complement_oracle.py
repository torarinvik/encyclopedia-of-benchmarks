"""Independent oracle for the bounded scalar Schur-complement contract."""

from __future__ import annotations

MAX_INPUT_LENGTH = 7  # includes one trailing-value malformed case
MAX_A_ENTRY = 8
MAX_BC_ENTRY = 100
INVALID_RESULT = -1.0e300
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1


def expected_result(values: list[int] | tuple[int, ...]) -> float:
    """Compute the 1x1 Schur complement or the finite invalid sentinel."""
    if (not isinstance(values, (list, tuple))
            or not 1 <= len(values) <= MAX_INPUT_LENGTH
            or any(type(value) is not int or not I64_MIN <= value <= I64_MAX
                   for value in values)):
        return INVALID_RESULT
    if len(values) != 6:
        return INVALID_RESULT

    a00, a01, a11, b0, b1, c00 = values
    if any(abs(value) > MAX_A_ENTRY for value in (a00, a01, a11)):
        return INVALID_RESULT
    if any(abs(value) > MAX_BC_ENTRY for value in (b0, b1, c00)):
        return INVALID_RESULT

    determinant = a00 * a11 - a01 * a01
    if determinant == 0:
        return INVALID_RESULT

    # Mirror C - B.T @ inv(A) @ B in the same left-to-right multiplication
    # order, using the exact inverse layout of this symmetric 2x2 matrix.
    inv00 = a11 / determinant
    inv01 = -a01 / determinant
    inv10 = -a01 / determinant
    inv11 = a00 / determinant
    left0 = float(b0) * inv00 + float(b1) * inv10
    left1 = float(b0) * inv01 + float(b1) * inv11
    quadratic = left0 * float(b0) + left1 * float(b1)
    return float(c00) - quadratic
