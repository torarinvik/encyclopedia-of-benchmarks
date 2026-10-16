"""Oracle for the bounded Go XOR missing-number search."""

from __future__ import annotations

MAX_N = 255
MAX_INPUT_LENGTH = MAX_N + 2  # admit one over-bound n with its full payload
INVALID_RESULT = -1


def expected_result(values: list[int]) -> int:
    if (not isinstance(values, list) or not 1 <= len(values) <= MAX_INPUT_LENGTH
            or any(type(value) is not int or not -(2**63) <= value <= 2**63 - 1
                   for value in values)):
        return INVALID_RESULT
    n = values[0]
    if not 0 <= n <= MAX_N or len(values) != n + 1:
        return INVALID_RESULT

    present: set[int] = set()
    for value in values[1:]:
        if not 0 <= value <= n or value in present:
            return INVALID_RESULT
        present.add(value)
    return next(value for value in range(n + 1) if value not in present)
