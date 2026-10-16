"""Independent brute-force oracle for the bounded histogram-area contract."""

from __future__ import annotations

MAX_VALID_INPUT_LENGTH = 64
MAX_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MIN_HEIGHT = 0
MAX_HEIGHT = 1_000_000
INVALID_RESULT = -(2**63)


def expected_result(heights: list[int]) -> int:
    """Return the largest histogram rectangle area, or the invalid sentinel."""
    if (not isinstance(heights, list) or len(heights) > MAX_VALID_INPUT_LENGTH
            or any(type(height) is not int or not MIN_HEIGHT <= height <= MAX_HEIGHT
                   for height in heights)):
        return INVALID_RESULT

    best = 0
    for start in range(len(heights)):
        minimum_height = MAX_HEIGHT
        for end in range(start, len(heights)):
            minimum_height = min(minimum_height, heights[end])
            best = max(best, minimum_height * (end - start + 1))
    return best
