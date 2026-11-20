"""Euclidean-GCD construction of a bounded Yellowstone prefix."""

from __future__ import annotations

from collections.abc import Sequence

MAX_N = 64
MIN_CANDIDATE_CAP = 3
MAX_CANDIDATE_CAP = 256
MAX_VALID_INPUT_LENGTH = 2
MAX_PARSEABLE_INPUT_LENGTH = 3
INVALID_RESULT = -1


def _parse(values: Sequence[int] | None, input_is_null: bool,
           input_length: int | None) -> tuple[int, int] | None:
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple))
            or not 1 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
            or any(type(word) is not int or not -(1 << 63) <= word < (1 << 63)
                   for word in values)):
        return None
    actual_length = len(values) if input_length is None else input_length
    if (type(actual_length) is not int or actual_length != len(values)
            or len(values) != MAX_VALID_INPUT_LENGTH):
        return None
    n, candidate_cap = values
    if not 1 <= n <= MAX_N or not MIN_CANDIDATE_CAP <= candidate_cap <= MAX_CANDIDATE_CAP:
        return None
    return n, candidate_cap


def _gcd(left: int, right: int) -> int:
    while right:
        left, right = right, left % right
    return left


def _construct(n: int, candidate_cap: int) -> list[int] | None:
    terms = [1, 2, 3]
    if n <= 3:
        return terms[:n]
    used = bytearray(candidate_cap + 1)
    used[1] = used[2] = used[3] = 1
    while len(terms) < n:
        two_back, previous = terms[-2], terms[-1]
        chosen = 0
        for candidate in range(1, candidate_cap + 1):
            if (not used[candidate]
                    and _gcd(candidate, two_back) > 1
                    and _gcd(candidate, previous) == 1):
                chosen = candidate
                break
        if chosen == 0:
            return None
        terms.append(chosen)
        used[chosen] = 1
    return terms


def expected_result(values: Sequence[int] | None, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    """Return the requested one-based term, or -1 for invalid/cap-exhausted input."""
    parsed = _parse(values, input_is_null, input_length)
    if parsed is None:
        return INVALID_RESULT
    n, candidate_cap = parsed
    terms = _construct(n, candidate_cap)
    return INVALID_RESULT if terms is None else terms[n - 1]
