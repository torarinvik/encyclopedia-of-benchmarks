"""Incremental greedy construction of the Mian–Chowla B2 sequence."""

from __future__ import annotations

from collections.abc import Sequence

MAX_N = 30
MAX_VALID_INPUT_LENGTH = 1
MAX_PARSEABLE_INPUT_LENGTH = 2
MAX_RESULT = 1_312
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
    n = values[0]
    if not 1 <= n <= MAX_N:
        return None
    return n


def _construct(n: int) -> list[int]:
    terms = [1]
    used_sums = {2}
    while len(terms) < n:
        candidate = terms[-1] + 1
        while True:
            if (2 * candidate not in used_sums
                    and all(candidate + term not in used_sums for term in terms)):
                break
            candidate += 1
        used_sums.update(candidate + term for term in terms)
        used_sums.add(2 * candidate)
        terms.append(candidate)
    return terms


def expected_result(values: Sequence[int] | None, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    """Return term n (one-based), or -1 for an invalid frame or index."""
    n = _parse(values, input_is_null, input_length)
    if n is None:
        return INVALID_RESULT
    return _construct(n)[-1]
