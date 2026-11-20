"""Binary-grouping reduction for bounded-multiplicity knapsack."""

from __future__ import annotations

MAX_TYPES = 16
MAX_CAPACITY = 64
MAX_WEIGHT = 16
MAX_VALUE = 100
MAX_COUNT = 16
INVALID_RESULT = -1
MAX_VALID_INPUT_LENGTH = 50
MAX_PARSEABLE_INPUT_LENGTH = 51
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
    if len(values) != 2 + 3 * n:
        return None
    items = []
    for offset in range(2, len(values), 3):
        weight, value, count = values[offset:offset + 3]
        if not 1 <= weight <= MAX_WEIGHT or not 0 <= value <= MAX_VALUE or not 0 <= count <= MAX_COUNT:
            return None
        items.append((weight, value, count))
    return capacity, items


def _binary_grouping(capacity: int, items: list[tuple[int, int, int]]) -> int:
    best = [0] * (capacity + 1)
    for weight, value, count in items:
        remaining = count
        bundle_size = 1
        while remaining > 0:
            copies = min(bundle_size, remaining)
            bundle_weight = weight * copies
            bundle_value = value * copies
            if bundle_weight <= capacity:
                for limit in range(capacity, bundle_weight - 1, -1):
                    best[limit] = max(best[limit], best[limit - bundle_weight] + bundle_value)
            remaining -= copies
            bundle_size *= 2
    return best[capacity]


def expected_result(values, input_is_null=False, input_length=None):
    parsed = _parse(values, input_is_null=input_is_null, input_length=input_length)
    if parsed is None:
        return INVALID_RESULT
    capacity, items = parsed
    return _binary_grouping(capacity, items)
