"""Reference bounded parallel/series capacitor equivalence."""

from __future__ import annotations

INVALID_RESULT = -1e300
MAX_CAPACITOR_COUNT = 32
MIN_CAPACITANCE = 0
MAX_CAPACITANCE = 1_000
MAX_INPUT_LENGTH = MAX_CAPACITOR_COUNT + 1
MAX_PARSEABLE_INPUT_LENGTH = MAX_INPUT_LENGTH + 1
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1


def expected_result(values: list[int] | tuple[int, ...]) -> float:
    """Decode `[operation, capacitor, ...]` and preserve source iteration order."""
    if (not isinstance(values, (list, tuple))
            or len(values) < 2
            or len(values) > MAX_PARSEABLE_INPUT_LENGTH
            or any(type(value) is not int or not I64_MIN <= value <= I64_MAX
                   for value in values)):
        return INVALID_RESULT

    operation, *capacitors = values
    if (operation not in (0, 1)
            or len(capacitors) > MAX_CAPACITOR_COUNT):
        return INVALID_RESULT

    if operation == 0:
        total = 0.0
        for capacitance in capacitors:
            if not MIN_CAPACITANCE <= capacitance <= MAX_CAPACITANCE:
                return INVALID_RESULT
            total += capacitance
        return total

    total_reciprocal = 0.0
    for capacitance in capacitors:
        if not 1 <= capacitance <= MAX_CAPACITANCE:
            return INVALID_RESULT
        total_reciprocal += 1 / capacitance
    return 1 / total_reciprocal
