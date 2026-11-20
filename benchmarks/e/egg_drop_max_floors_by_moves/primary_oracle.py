"""Move-major egg-drop coverage recurrence."""

from __future__ import annotations

from collections.abc import Sequence

MAX_EGGS = 32
MAX_MOVES = 32
MAX_VALID_INPUT_LENGTH = 2
MAX_PARSEABLE_INPUT_LENGTH = 3
MAX_RESULT = (1 << MAX_MOVES) - 1
MAX_WORKSPACE_BYTES = (MAX_EGGS + 1) * 8
INVALID_RESULT = -1


def expected_result(values: Sequence[int] | None, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple))
            or len(values) != MAX_VALID_INPUT_LENGTH
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return INVALID_RESULT
    if input_length is not None and (
            type(input_length) is not int or input_length != len(values)):
        return INVALID_RESULT
    eggs, moves = values
    if not 0 <= eggs <= MAX_EGGS or not 0 <= moves <= MAX_MOVES:
        return INVALID_RESULT

    covered = [0] * (MAX_EGGS + 1)
    for _ in range(moves):
        for egg_count in range(eggs, 0, -1):
            covered[egg_count] += covered[egg_count - 1] + 1
    return covered[eggs]
