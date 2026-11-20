"""Binary-search feasibility reference for linear partition minimax."""

from __future__ import annotations

from collections.abc import Sequence

MAX_N = 32
MIN_VALUE = 0
MAX_VALUE = 1000
MAX_VALID_INPUT_LENGTH = 34
MAX_PARSEABLE_INPUT_LENGTH = 35
WORKSPACE_BYTES = 1024
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1


def _parse(values: Sequence[int] | None, input_length: int | None,
           input_is_null: bool) -> tuple[int, list[int], int] | None:
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple))
            or not 3 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
            or any(type(value) is not int or not I64_MIN <= value <= I64_MAX
                   for value in values)):
        return None
    if input_length is not None and (
        type(input_length) is not int or input_length != len(values)
    ):
        return None
    n, groups = values[0], values[1]
    if not 1 <= n <= MAX_N or not 1 <= groups <= n:
        return None
    if len(values) != n + 2:
        return None
    items = list(values[2:])
    if len(items) != n or any(not MIN_VALUE <= item <= MAX_VALUE for item in items):
        return None
    return n, items, groups


def _uses_at_most_groups(items: list[int], groups: int, limit: int) -> bool:
    used_groups = 1
    current_sum = 0
    for item in items:
        if current_sum + item > limit:
            used_groups += 1
            current_sum = item
            if used_groups > groups:
                return False
        else:
            current_sum += item
    return True


def expected_result(values: Sequence[int] | None, input_length: int | None = None,
                    input_is_null: bool = False) -> int:
    parsed = _parse(values, input_length, input_is_null)
    if parsed is None:
        return -1
    _, items, groups = parsed
    low = max(items)
    high = sum(items)
    while low < high:
        middle = (low + high) // 2
        if _uses_at_most_groups(items, groups, middle):
            high = middle
        else:
            low = middle + 1
    return low
