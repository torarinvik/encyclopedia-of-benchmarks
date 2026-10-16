"""Independent oracle for the bounded maximum-product subarray contract."""

from __future__ import annotations

MAX_VALID_INPUT_LENGTH = 9
MAX_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MIN_VALUE = -10
MAX_VALUE = 10
INVALID_RESULT = -(2**63)


def expected_result(values: list[int]) -> int:
    """Return the largest product of a nonempty contiguous segment, or sentinel."""
    if (not isinstance(values, list) or not 1 <= len(values) <= MAX_VALID_INPUT_LENGTH
            or any(type(value) is not int or not MIN_VALUE <= value <= MAX_VALUE
                   for value in values)):
        return INVALID_RESULT

    best = None
    for start in range(len(values)):
        product = 1
        for value in values[start:]:
            product *= value
            best = product if best is None else max(best, product)
    assert best is not None
    return best
