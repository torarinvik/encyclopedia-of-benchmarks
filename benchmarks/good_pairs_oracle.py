"""Independent bounded oracle for the brute-force good-pairs benchmark."""

from __future__ import annotations

I64_MIN = -(2**63)
I64_MAX = 2**63 - 1
MAX_N = 256
MIN_VALUE = -1_000_000
MAX_VALUE = 1_000_000
MAX_INPUT_LENGTH = MAX_N + 1


def expected_result(values: list[int] | tuple[int, ...]) -> int:
    """Count equal-value pairs using frequencies; malformed packed inputs return -1."""
    if (not isinstance(values, (list, tuple)) or not values
            or len(values) > MAX_INPUT_LENGTH
            or any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values)):
        return -1

    n = values[0]
    if n < 0 or n > MAX_N or len(values) != n + 1:
        return -1

    seen: dict[int, int] = {}
    pairs = 0
    for value in values[1:]:
        if not MIN_VALUE <= value <= MAX_VALUE:
            return -1
        pairs += seen.get(value, 0)
        seen[value] = seen.get(value, 0) + 1
    return pairs
