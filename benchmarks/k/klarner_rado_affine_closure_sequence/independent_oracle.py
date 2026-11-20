"""Min-heap closure reference, independent of the primary stream merge."""

from __future__ import annotations

from collections.abc import Sequence
from heapq import heappop, heappush

from .primary_oracle import (
    INVALID_RESULT,
    MAX_INDEX,
    MAX_PARSEABLE_INPUT_LENGTH,
    MAX_VALID_INPUT_LENGTH,
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
    if (type(actual_length) is not int or actual_length != len(values)
            or len(values) != MAX_VALID_INPUT_LENGTH):
        return None
    requested = values[0]
    return requested if 1 <= requested <= MAX_INDEX else None


def _enumerate(requested: int) -> int:
    pending = [1]
    seen = {1}
    for index in range(requested):
        current = heappop(pending)
        if index + 1 == requested:
            break
        for child in (2 * current, 3 * current + 2, 6 * current + 3):
            if child not in seen:
                seen.add(child)
                heappush(pending, child)
    return current


def expected_result(values: Sequence[int] | None, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    requested = _parse(values, input_is_null, input_length)
    if requested is None:
        return INVALID_RESULT
    return _enumerate(requested)
