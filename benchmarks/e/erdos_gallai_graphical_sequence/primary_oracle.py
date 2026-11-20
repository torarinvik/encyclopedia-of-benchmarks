"""Prefix-sum and binary-search Erdős–Gallai reference."""

from __future__ import annotations

MAX_VERTICES = 256
MAX_INPUT_LENGTH = MAX_VERTICES + 1
MAX_PARSEABLE_INPUT_LENGTH = MAX_INPUT_LENGTH + 1
WORKSPACE_BYTES = 8192


def _decode(values, input_is_null: bool, input_length: int | None):
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple))
            or len(values) > MAX_PARSEABLE_INPUT_LENGTH
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return None
    if input_length is not None and (
            type(input_length) is not int or input_length != len(values)):
        return None
    if not values or not 0 <= values[0] <= MAX_VERTICES or len(values) != values[0] + 1:
        return None
    n = values[0]
    degrees = values[1:]
    if any(degree < 0 or degree >= n for degree in degrees):
        return None
    return n, degrees


def expected_result(values, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    decoded = _decode(values, input_is_null, input_length)
    if decoded is None:
        return -1
    n, degrees = decoded
    ordered = sorted(degrees, reverse=True)
    prefix = [0] * (n + 1)
    for index, degree in enumerate(ordered, 1):
        prefix[index] = prefix[index - 1] + degree
    if prefix[n] & 1:
        return 0

    for k in range(1, n + 1):
        low, high = k, n
        while low < high:
            middle = (low + high) // 2
            if ordered[middle] >= k:
                low = middle + 1
            else:
                high = middle
        split = low
        right_hand_side = (k * (k - 1) + k * (split - k)
                           + prefix[n] - prefix[split])
        if prefix[k] > right_hand_side:
            return 0
    return 1
