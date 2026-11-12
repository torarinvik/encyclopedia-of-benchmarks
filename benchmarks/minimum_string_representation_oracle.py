"""Candidate-elimination oracle for a least cyclic-rotation start index."""

from __future__ import annotations

from collections.abc import Sequence

MAX_LENGTH = 4096
MAX_PARSEABLE_INPUT_LENGTH = MAX_LENGTH + 1
INVALID_RESULT = -1


def _parse(values: Sequence[int] | None, input_length: int | None,
           input_is_null: bool) -> list[int] | None:
    if type(input_is_null) is not bool:
        return None
    if input_length is not None and (type(input_length) is not int or input_length < 0):
        return None
    if input_length is not None and input_length > MAX_LENGTH:
        return None
    if input_length == 0:
        return []
    if input_is_null or not isinstance(values, (list, tuple)):
        return None
    length = len(values) if input_length is None else input_length
    if length > MAX_LENGTH or len(values) != length:
        return None
    if any(type(value) is not int or not 0 <= value <= 127 for value in values):
        return None
    return list(values)


def expected_result(values: Sequence[int] | None, input_length: int | None = None,
                    input_is_null: bool = False) -> int:
    """Return the minimum-string index, or -1 for an invalid input frame."""
    text = _parse(values, input_length, input_is_null)
    if text is None:
        return INVALID_RESULT
    n = len(text)
    if n == 0:
        return 0

    left, right, matched = 0, 1, 0
    while left < n and right < n and matched < n:
        a = text[(left + matched) % n]
        b = text[(right + matched) % n]
        if a == b:
            matched += 1
            continue
        if a > b:
            left += matched + 1
            if left == right:
                left += 1
        else:
            right += matched + 1
            if left == right:
                right += 1
        matched = 0
    return min(left, right)
