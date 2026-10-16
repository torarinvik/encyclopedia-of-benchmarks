"""Source contract for the pinned monotonic-array predicate."""
from __future__ import annotations

MAX_INPUT_LENGTH = 256
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1
INVALID_RESULT = -1


def expected_result(values: list[int]) -> int:
    if len(values) > MAX_INPUT_LENGTH or any(
        value < I64_MIN or value > I64_MAX for value in values
    ):
        return INVALID_RESULT

    # Preserve the pinned source's first all() followed by a short-circuited second.
    nondecreasing = all(values[i] <= values[i + 1] for i in range(len(values) - 1))
    if nondecreasing:
        return 1
    nonincreasing = all(values[i] >= values[i + 1] for i in range(len(values) - 1))
    return int(nonincreasing)
