"""Trial-factor/set-intersection reference for the bounded Yellowstone prefix."""

from __future__ import annotations

from collections.abc import Sequence

from .primary_oracle import (
    INVALID_RESULT,
    MAX_CANDIDATE_CAP,
    MAX_N,
    MAX_PARSEABLE_INPUT_LENGTH,
    MAX_VALID_INPUT_LENGTH,
    MIN_CANDIDATE_CAP,
)


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


def _prime_factors(value: int) -> set[int]:
    factors: set[int] = set()
    divisor = 2
    while divisor * divisor <= value:
        if value % divisor == 0:
            factors.add(divisor)
            while value % divisor == 0:
                value //= divisor
        divisor += 1
    if value > 1:
        factors.add(value)
    return factors


def _shares_factor(left_factors: set[int], right_factors: set[int]) -> bool:
    return not left_factors.isdisjoint(right_factors)


def _construct_by_factor_sets(n: int, candidate_cap: int) -> list[int] | None:
    terms = [1, 2, 3]
    if n <= 3:
        return terms[:n]
    factor_sets = [_prime_factors(term) for term in terms]
    while len(terms) < n:
        two_back_factors = factor_sets[-2]
        previous_factors = factor_sets[-1]
        chosen = 0
        for candidate in range(1, candidate_cap + 1):
            if candidate in terms:
                continue
            candidate_factors = _prime_factors(candidate)
            if (_shares_factor(candidate_factors, two_back_factors)
                    and not _shares_factor(candidate_factors, previous_factors)):
                chosen = candidate
                terms.append(candidate)
                factor_sets.append(candidate_factors)
                break
        if chosen == 0:
            return None
    return terms


def expected_result(values: Sequence[int] | None, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    parsed = _parse(values, input_is_null, input_length)
    if parsed is None:
        return INVALID_RESULT
    n, candidate_cap = parsed
    terms = _construct_by_factor_sets(n, candidate_cap)
    return INVALID_RESULT if terms is None else terms[n - 1]
