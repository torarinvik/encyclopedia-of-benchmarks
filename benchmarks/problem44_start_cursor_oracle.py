"""Independent exact oracle for the bounded Problem 44 start-cursor search."""

from functools import lru_cache

MAX_START = 2166
MAX_HIGH_INDEX = 2167


def _pentagonal(index: int) -> int:
    return index * (3 * index - 1) // 2


@lru_cache(maxsize=1)
def _pentagonal_values() -> frozenset[int]:
    """Generate all pentagonal values large enough to cover every pair sum."""
    maximum_sum = _pentagonal(MAX_HIGH_INDEX) + _pentagonal(MAX_HIGH_INDEX - 1)
    values: set[int] = set()
    index = 1
    while True:
        value = _pentagonal(index)
        if value > maximum_sum:
            return frozenset(values)
        values.add(value)
        index += 1


def expected_result(start: int) -> int:
    """Return the first matching pair using a generated-value membership oracle.

    Membership is independent of the ports' discriminant/square-root test: this
    oracle constructs the finite pentagonal set directly from its definition.
    """
    if isinstance(start, bool) or not isinstance(start, int) or not 1 <= start <= MAX_START:
        return -1

    pentagonal_values = _pentagonal_values()
    for high_index in range(start + 1, MAX_HIGH_INDEX + 1):
        high_value = _pentagonal(high_index)
        for low_index in range(high_index - 1, 0, -1):
            low_value = _pentagonal(low_index)
            difference = high_value - low_value
            total = high_value + low_value
            if difference in pentagonal_values and total in pentagonal_values:
                return difference
    return -1
