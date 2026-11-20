"""Breadth-first search for bounded left-truncatable primes."""

from __future__ import annotations

from collections.abc import Sequence

MIN_BASE = 3
MAX_BASE = 16
MAX_DIGITS = 10
MAX_SEARCH_LIMIT = 100_000
MAX_QUEUE = 70_000
MAX_VALID_INPUT_LENGTH = 2
MAX_PARSEABLE_INPUT_LENGTH = 3
INVALID_RESULT = -1


def _parse(values: Sequence[int] | None, input_is_null: bool,
           input_length: int | None) -> tuple[int, int] | None:
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple))
            or not 2 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
            or any(type(word) is not int or not -(1 << 63) <= word < (1 << 63)
                   for word in values)):
        return None
    actual_length = len(values) if input_length is None else input_length
    if type(actual_length) is not int or actual_length != len(values) or len(values) != 2:
        return None
    base, max_digits = values
    if not MIN_BASE <= base <= MAX_BASE or not 1 <= max_digits <= MAX_DIGITS:
        return None
    limit = 1
    for _ in range(max_digits):
        limit *= base
    if limit > MAX_SEARCH_LIMIT:
        return None
    return base, max_digits


def _is_prime(value: int) -> bool:
    if value < 2:
        return False
    if value % 2 == 0:
        return value == 2
    divisor = 3
    while divisor * divisor <= value:
        if value % divisor == 0:
            return False
        divisor += 2
    return True


def _search(base: int, max_digits: int) -> int:
    frontier = [value for value in range(2, base) if _is_prime(value)]
    best = frontier[-1] if frontier else 0
    place = base
    digit_length = 1
    while digit_length < max_digits and frontier:
        next_frontier: list[int] = []
        for suffix in frontier:
            for leading_digit in range(1, base):
                candidate = leading_digit * place + suffix
                if _is_prime(candidate):
                    next_frontier.append(candidate)
                    if candidate > best:
                        best = candidate
        frontier = next_frontier
        place *= base
        digit_length += 1
    return best


def expected_result(values: Sequence[int] | None, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    """Return the largest qualifying value, or -1 for an invalid frame."""
    parsed = _parse(values, input_is_null, input_length)
    if parsed is None:
        return INVALID_RESULT
    return _search(*parsed)
