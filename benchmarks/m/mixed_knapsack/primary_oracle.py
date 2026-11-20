"""Mode-dispatched 0/1, complete, and bounded knapsack dynamic program."""

from __future__ import annotations

MAX_TYPES = 16
MAX_CAPACITY = 64
MAX_WEIGHT = 16
MAX_VALUE = 100
MAX_BOUNDED_COUNT = 16
INVALID_RESULT = -1
MAX_VALID_INPUT_LENGTH = 66
MAX_PARSEABLE_INPUT_LENGTH = 67
MAX_WORKSPACE_BYTES = 1024


def _parse(values, input_is_null=False, input_length=None):
    if input_is_null or not isinstance(values, (list, tuple)):
        return None
    if (len(values) < 2 or len(values) > MAX_PARSEABLE_INPUT_LENGTH
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return None
    if input_length is not None and (
        type(input_length) is not int or input_length != len(values)
    ):
        return None
    n, capacity = values[:2]
    if not 0 <= n <= MAX_TYPES or not 0 <= capacity <= MAX_CAPACITY:
        return None
    if len(values) != 2 + 4 * n:
        return None
    items = []
    for offset in range(2, len(values), 4):
        mode, weight, value, limit = values[offset:offset + 4]
        if mode not in (0, 1, 2) or not 1 <= weight <= MAX_WEIGHT or not 0 <= value <= MAX_VALUE:
            return None
        if mode == 0 and limit != 1:
            return None
        if mode == 1 and limit != 0:
            return None
        if mode == 2 and not 0 <= limit <= MAX_BOUNDED_COUNT:
            return None
        items.append((mode, weight, value, limit))
    return capacity, items


def _bounded_update(best: list[int], capacity: int, weight: int,
                    value: int, count: int) -> None:
    remaining = count
    bundle_size = 1
    while remaining > 0:
        copies = min(bundle_size, remaining)
        bundle_weight = copies * weight
        bundle_value = copies * value
        if bundle_weight <= capacity:
            for limit in range(capacity, bundle_weight - 1, -1):
                best[limit] = max(best[limit], best[limit - bundle_weight] + bundle_value)
        remaining -= copies
        bundle_size *= 2


def _mixed_dp(capacity: int, items: list[tuple[int, int, int, int]]) -> int:
    best = [0] * (capacity + 1)
    for mode, weight, value, limit in items:
        if mode == 0:
            for current_capacity in range(capacity, weight - 1, -1):
                best[current_capacity] = max(
                    best[current_capacity], best[current_capacity - weight] + value
                )
        elif mode == 1:
            for current_capacity in range(weight, capacity + 1):
                best[current_capacity] = max(
                    best[current_capacity], best[current_capacity - weight] + value
                )
        else:
            _bounded_update(best, capacity, weight, value, limit)
    return best[capacity]


def expected_result(values, input_is_null=False, input_length=None):
    parsed = _parse(values, input_is_null=input_is_null, input_length=input_length)
    if parsed is None:
        return INVALID_RESULT
    capacity, items = parsed
    return _mixed_dp(capacity, items)
