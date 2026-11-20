"""Inclusion-exclusion reference for the Eulerian descent-count triangle."""

from __future__ import annotations

from collections.abc import Sequence
from math import comb

MAX_N = 20
MAX_VALID_INPUT_LENGTH = 2
MAX_PARSEABLE_INPUT_LENGTH = 3
MAX_WORKSPACE_BYTES = 512
INVALID_RESULT = -1
I64_MIN, I64_MAX = -(1 << 63), (1 << 63) - 1


def expected_result(values: Sequence[int] | None, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple))
            or not 1 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
            or any(type(word) is not int or word < I64_MIN or word > I64_MAX
                   for word in values)):
        return INVALID_RESULT
    if input_length is not None and (
            type(input_length) is not int or input_length != len(values)):
        return INVALID_RESULT
    if len(values) != MAX_VALID_INPUT_LENGTH:
        return INVALID_RESULT
    n, k = values
    if (not 0 <= n <= MAX_N or k < 0
            or (n == 0 and k != 0) or (n > 0 and k >= n)):
        return INVALID_RESULT
    if n == 0:
        return 1
    return sum(
        (-1 if j % 2 else 1) * comb(n + 1, j) * (k + 1 - j) ** n
        for j in range(k + 2)
    )
