"""Primary scalar reference for Liu Hui's polygon-doubling area method."""

from __future__ import annotations

import math

MIN_DOUBLINGS = 0
MAX_DOUBLINGS = 16
OUTPUT_SCALE = 1_000_000
INVALID_RESULT = -1


def expected_output(doublings: int) -> int:
    if type(doublings) is not int or not MIN_DOUBLINGS <= doublings <= MAX_DOUBLINGS:
        return INVALID_RESULT

    sides = 6
    side = 1.0
    apothem = math.sqrt(0.75)
    for _ in range(doublings):
        half_side = side / 2.0
        height = 1.0 - apothem
        side = math.sqrt(half_side * half_side + height * height)
        sides *= 2
        half_side = side / 2.0
        apothem = math.sqrt(1.0 - half_side * half_side)

    area = sides * side * apothem / 2.0
    return math.floor(area * OUTPUT_SCALE + 0.5)
