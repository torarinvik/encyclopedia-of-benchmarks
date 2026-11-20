"""Interpolated starting position followed by a directional linear scan."""

from __future__ import annotations

from collections.abc import Sequence

MAX_N = 64
MAX_VALID_INPUT_LENGTH = MAX_N + 2
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MIN_VALUE = -1_000_000
MAX_VALUE = 1_000_000
MAX_WORKSPACE_BYTES = 0
INVALID_RESULT = -1


def _decode(values: Sequence[int] | None, input_is_null: bool,
            input_length: int | None):
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple))
            or not 2 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
            or any(type(word) is not int or not -(1 << 63) <= word < (1 << 63)
                   for word in values)):
        return None
    if input_length is not None and (
            type(input_length) is not int or input_length != len(values)):
        return None
    n, target = values[:2]
    if (not 0 <= n <= MAX_N or len(values) != n + 2
            or not MIN_VALUE <= target <= MAX_VALUE):
        return None
    items = values[2:]
    if (any(not MIN_VALUE <= item <= MAX_VALUE for item in items)
            or any(items[i - 1] >= items[i] for i in range(1, n))):
        return None
    return n, target, items


def expected_result(values: Sequence[int] | None, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    parsed = _decode(values, input_is_null, input_length)
    if parsed is None:
        return INVALID_RESULT
    n, target, items = parsed
    if n == 0 or target < items[0] or target > items[-1]:
        return INVALID_RESULT
    if n == 1:
        return 0 if items[0] == target else INVALID_RESULT

    first = items[0]
    last = items[-1]
    position = ((target - first) * (n - 1)) // (last - first)
    position = min(max(position, 0), n - 1)
    if items[position] == target:
        return position
    if items[position] < target:
        for index in range(position + 1, n):
            if items[index] >= target:
                return index if items[index] == target else INVALID_RESULT
    else:
        for index in range(position - 1, -1, -1):
            if items[index] <= target:
                return index if items[index] == target else INVALID_RESULT
    return INVALID_RESULT
