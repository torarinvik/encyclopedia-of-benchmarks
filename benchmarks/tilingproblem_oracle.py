"""Oracle for bounded 2-by-n domino tiling counts."""

from __future__ import annotations

MAX_INPUT_LENGTH = 2
MAX_WIDTH = 91


def expected_result(values: list[int] | tuple[int, ...]) -> int:
    if (not isinstance(values, (list, tuple)) or not 1 <= len(values) <= MAX_INPUT_LENGTH
            or any(type(value) is not int or not -(2**63) <= value < 2**63 for value in values)
            or len(values) != 1):
        return -1
    width = values[0]
    if not 0 <= width <= MAX_WIDTH:
        return -1
    previous, current = 1, 1
    for _ in range(2, width + 1):
        previous, current = current, previous + current
    return current
