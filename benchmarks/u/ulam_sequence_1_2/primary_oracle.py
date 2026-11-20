"""Incremental representation-count construction for U(1,2)."""

from __future__ import annotations

from collections.abc import Sequence

ALGORITHM = "ulam_sequence_1_2"
MAX_N = 14
MAX_CANDIDATE = 64
MAX_SUM = 74
MAX_RESULT = 38
MAX_VALID_INPUT_LENGTH = 1
MAX_PARSEABLE_INPUT_LENGTH = 2
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
    if type(actual_length) is not int or actual_length != len(values) or len(values) != 1:
        return None
    requested = values[0]
    if not 1 <= requested <= MAX_N:
        return None
    return requested


def _construct(requested: int) -> int:
    terms = [1, 2]
    if requested <= 2:
        return terms[requested - 1]

    # Counts are saturated at 2: only zero, one, or multiple representations
    # matter. Every sum through the 14th term is at most 38 + 36 = 74.
    representations = [0] * (MAX_SUM + 1)
    representations[3] = 1
    while len(terms) < requested:
        candidate = terms[-1] + 1
        while candidate <= MAX_CANDIDATE and representations[candidate] != 1:
            candidate += 1
        if candidate > MAX_CANDIDATE:
            return INVALID_RESULT
        for old_term in terms:
            total = candidate + old_term
            if representations[total] < 2:
                representations[total] += 1
        terms.append(candidate)
    return terms[-1]


def expected_result(values: Sequence[int] | None, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    """Return U_k for 1<=k<=14, or -1 for an invalid frame/index."""
    requested = _parse(values, input_is_null, input_length)
    if requested is None:
        return INVALID_RESULT
    return _construct(requested)
