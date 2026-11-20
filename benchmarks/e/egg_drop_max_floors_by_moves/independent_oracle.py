"""Independent partial-binomial formula for egg-drop floor coverage."""

from __future__ import annotations

from collections.abc import Sequence

MAX_EGGS = 32
MAX_MOVES = 32
MAX_RESULT = (1 << MAX_MOVES) - 1
INVALID_RESULT = -1


def expected_result(values: Sequence[int] | None, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple)) or len(values) != 2
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return INVALID_RESULT
    if input_length is not None and (
            type(input_length) is not int or input_length != len(values)):
        return INVALID_RESULT
    eggs, moves = values
    if not 0 <= eggs <= MAX_EGGS or not 0 <= moves <= MAX_MOVES:
        return INVALID_RESULT

    total = 0
    coefficient = 1
    for selected in range(1, min(eggs, moves) + 1):
        coefficient = coefficient * (moves - selected + 1) // selected
        total += coefficient
    return total
