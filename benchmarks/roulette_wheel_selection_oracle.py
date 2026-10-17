"""Independent oracle for deterministic weighted validator selection."""

from __future__ import annotations

I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1
MIN_VALIDATORS = 1
MAX_VALIDATORS = 128
MIN_STAKE = 1
MAX_STAKE = 1_000_000
MAX_TOTAL_STAKE = 128_000_000
MAX_VALID_INPUT_LENGTH = 130
MAX_INPUT_LENGTH = 131
INVALID_RESULT = -1


def expected_result(values: list[int] | tuple[int, ...]) -> int:
    """Return the one-based selected validator index, or -1 for invalid input."""
    if (
        not isinstance(values, (list, tuple))
        or len(values) < 3
        or len(values) > MAX_INPUT_LENGTH
        or any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values)
    ):
        return INVALID_RESULT

    count = values[0]
    if not MIN_VALIDATORS <= count <= MAX_VALIDATORS:
        return INVALID_RESULT
    if len(values) != count + 2:
        return INVALID_RESULT

    stakes = values[1 : 1 + count]
    if any(not MIN_STAKE <= stake <= MAX_STAKE for stake in stakes):
        return INVALID_RESULT

    total = sum(stakes)
    if not 1 <= total <= MAX_TOTAL_STAKE:
        return INVALID_RESULT
    ticket = values[1 + count]
    if not 0 <= ticket < total:
        return INVALID_RESULT

    cumulative = 0
    for index, stake in enumerate(stakes, start=1):
        cumulative += stake
        if ticket < cumulative:
            return index
    return INVALID_RESULT
