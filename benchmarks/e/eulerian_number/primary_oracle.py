"""Eulerian-row recurrence for permutations indexed by their descents."""

from __future__ import annotations

from collections.abc import Sequence

MAX_N = 20
MAX_VALID_INPUT_LENGTH = 2
MAX_PARSEABLE_INPUT_LENGTH = 3
MAX_RESULT = 2_432_902_008_176_640_000  # 20!
MAX_WORKSPACE_BYTES = 512
INVALID_RESULT = -1
I64_MIN, I64_MAX = -(1 << 63), (1 << 63) - 1


def _parse(values: Sequence[int] | None, input_is_null: bool,
           input_length: int | None) -> tuple[int, int] | None:
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple))
            or not 1 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
            or any(type(word) is not int or not I64_MIN <= word <= I64_MAX
                   for word in values)):
        return None
    if input_length is not None and (
            type(input_length) is not int or input_length != len(values)):
        return None
    if len(values) != MAX_VALID_INPUT_LENGTH:
        return None
    n, k = values
    if (not 0 <= n <= MAX_N or k < 0
            or (n == 0 and k != 0) or (n > 0 and k >= n)):
        return None
    return n, k


def expected_result(values: Sequence[int] | None, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    parsed = _parse(values, input_is_null, input_length)
    if parsed is None:
        return INVALID_RESULT
    n, target = parsed
    previous = [1] + [0] * MAX_N
    for row in range(1, n + 1):
        current = [0] * (MAX_N + 1)
        for k in range(row):
            same = previous[k]
            fewer = previous[k - 1] if k > 0 else 0
            current[k] = (k + 1) * same + (row - k) * fewer
        previous = current
    return previous[target]
