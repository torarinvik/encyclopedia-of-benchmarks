"""Candidate-by-candidate pair enumeration reference for U(1,2)."""

from __future__ import annotations

from collections.abc import Sequence

from .primary_oracle import (
    INVALID_RESULT,
    MAX_CANDIDATE,
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


def _representations(terms: list[int], candidate: int) -> int:
    count = 0
    for left in range(len(terms)):
        for right in range(left + 1, len(terms)):
            if terms[left] + terms[right] == candidate:
                count += 1
                if count > 1:
                    return count
    return count


def _construct_by_recounting(requested: int) -> int:
    terms = [1, 2]
    while len(terms) < requested:
        candidate = terms[-1] + 1
        while (candidate <= MAX_CANDIDATE
               and _representations(terms, candidate) != 1):
            candidate += 1
        if candidate > MAX_CANDIDATE:
            return INVALID_RESULT
        terms.append(candidate)
    return terms[-1]


def expected_result(values: Sequence[int] | None, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    requested = _parse(values, input_is_null, input_length)
    if requested is None:
        return INVALID_RESULT
    return _construct_by_recounting(requested)
