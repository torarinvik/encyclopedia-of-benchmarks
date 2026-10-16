"""Independent bounded oracle for the finite arithmetic-series sum."""

from __future__ import annotations

INVALID_RESULT = -1e300
MAX_ABSOLUTE_TERM = 1_000
MAX_TERM_COUNT = 1_000


def expected_result(values: list[int] | tuple[int, ...]) -> float:
    """Return n * (2*a + (n-1)*d) / 2 within the benchmark domain."""
    if (not isinstance(values, (list, tuple)) or len(values) != 3
            or any(type(value) is not int for value in values)):
        return INVALID_RESULT
    first_term, common_difference, term_count = values
    if (not -MAX_ABSOLUTE_TERM <= first_term <= MAX_ABSOLUTE_TERM
            or not -MAX_ABSOLUTE_TERM <= common_difference <= MAX_ABSOLUTE_TERM
            or not 1 <= term_count <= MAX_TERM_COUNT):
        return INVALID_RESULT
    numerator = term_count * (2 * first_term + (term_count - 1) * common_difference)
    return float(numerator // 2)
