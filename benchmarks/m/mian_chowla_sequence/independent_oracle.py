"""Recomputed pair-sum uniqueness reference for the Mian–Chowla sequence."""

from __future__ import annotations

from collections.abc import Sequence

from .primary_oracle import (
    INVALID_RESULT,
    MAX_N,
    MAX_PARSEABLE_INPUT_LENGTH,
)


def _parse(values: Sequence[int] | None, input_is_null: bool,
           input_length: int | None) -> int | None:
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple))
            or not 1 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
            or any(type(word) is not int or not -(1 << 63) <= word < (1 << 63)
                   for word in values)):
        return None
    actual_length = len(values) if input_length is None else input_length
    if type(actual_length) is not int or actual_length != len(values) or len(values) != 1:
        return None
    if not 1 <= values[0] <= MAX_N:
        return None
    return values[0]


def _unique_pair_sums(terms: list[int]) -> bool:
    observed: set[int] = set()
    for left in range(len(terms)):
        for right in range(left, len(terms)):
            total = terms[left] + terms[right]
            if total in observed:
                return False
            observed.add(total)
    return True


def _construct_by_recomputation(n: int) -> list[int]:
    terms = [1]
    while len(terms) < n:
        candidate = terms[-1] + 1
        while not _unique_pair_sums(terms + [candidate]):
            candidate += 1
        terms.append(candidate)
    return terms


def expected_result(values: Sequence[int] | None, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    n = _parse(values, input_is_null, input_length)
    if n is None:
        return INVALID_RESULT
    return _construct_by_recomputation(n)[-1]
