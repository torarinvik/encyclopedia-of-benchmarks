"""Linear stream-merge reference for the Klarner–Rado A005658 sequence."""

from __future__ import annotations

from collections.abc import Sequence

MAX_INDEX = 64
MAX_VALID_INPUT_LENGTH = 1
MAX_PARSEABLE_INPUT_LENGTH = 2
MAX_RESULT = 120
MAX_CANDIDATE = 699
WORKSPACE_BYTES = 1_024
INVALID_RESULT = -1


def _parse(values: Sequence[int] | None, input_is_null: bool,
           input_length: int | None) -> int | None:
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
    requested = values[0]
    if not 1 <= requested <= MAX_INDEX:
        return None
    return requested


def _construct(requested: int) -> int:
    terms = [1]
    twice = thrice_plus_two = sixfold_plus_three = 0
    while len(terms) < requested:
        candidate_twice = 2 * terms[twice]
        candidate_thrice = 3 * terms[thrice_plus_two] + 2
        candidate_sixfold = 6 * terms[sixfold_plus_three] + 3
        next_term = min(candidate_twice, candidate_thrice, candidate_sixfold)
        terms.append(next_term)
        if candidate_twice == next_term:
            twice += 1
        if candidate_thrice == next_term:
            thrice_plus_two += 1
        if candidate_sixfold == next_term:
            sixfold_plus_three += 1
    return terms[-1]


def expected_result(values: Sequence[int] | None, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    """Return the one-based kth A005658 term, or -1 for a malformed frame."""
    requested = _parse(values, input_is_null, input_length)
    if requested is None:
        return INVALID_RESULT
    return _construct(requested)
