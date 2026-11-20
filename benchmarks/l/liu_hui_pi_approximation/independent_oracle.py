"""Independent direct-angle area reference for the polygon approximation."""

from __future__ import annotations

import math

MIN_DOUBLINGS = 0
MAX_DOUBLINGS = 16
OUTPUT_SCALE = 1_000_000
INVALID_RESULT = -1


def expected_output(doublings: int) -> int:
    if type(doublings) is not int or not MIN_DOUBLINGS <= doublings <= MAX_DOUBLINGS:
        return INVALID_RESULT
    sides = 6 << doublings
    area = (sides / 2.0) * math.sin((2.0 * math.pi) / sides)
    return math.floor(area * OUTPUT_SCALE + 0.5)
