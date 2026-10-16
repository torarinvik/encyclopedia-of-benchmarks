"""Independent contract oracle for the uint53 XOR benchmark."""

from __future__ import annotations

MAX_UINT53 = 9_007_199_254_740_991


def expected_result(left: int, right: int) -> int:
    """Return the XOR result for exact nonnegative uint53 operands."""
    if (type(left) is not int or type(right) is not int
            or not 0 <= left <= MAX_UINT53 or not 0 <= right <= MAX_UINT53):
        return -1
    return left ^ right
