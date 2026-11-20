"""Integer-threshold binary search for a maximum-average subarray."""

from __future__ import annotations

MAX_N = 32
MIN_VALUE = -1000
MAX_VALUE = 1000
SCALE = 1000
MIN_RESULT = MIN_VALUE * SCALE
MAX_RESULT = MAX_VALUE * SCALE
INVALID_RESULT = -1_000_001
MAX_VALID_INPUT_LENGTH = 34
MAX_PARSEABLE_INPUT_LENGTH = 35
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
    n, minimum_length = values[:2]
    if not 1 <= n <= MAX_N or not 1 <= minimum_length <= n:
        return None
    if len(values) != n + 2:
        return None
    data = values[2:]
    if any(not MIN_VALUE <= value <= MAX_VALUE for value in data):
        return None
    return n, minimum_length, data


def _feasible(data: list[int], minimum_length: int, threshold: int) -> bool:
    prefix = [0] * (len(data) + 1)
    for index, value in enumerate(data):
        prefix[index + 1] = prefix[index] + SCALE * value - threshold

    minimum_prefix = 0
    for end in range(minimum_length, len(data) + 1):
        eligible_start = end - minimum_length
        if prefix[eligible_start] < minimum_prefix or eligible_start == 0:
            minimum_prefix = prefix[eligible_start]
        if prefix[end] >= minimum_prefix:
            return True
    return False


def expected_result(values, input_is_null=False, input_length=None):
    parsed = _parse(values, input_is_null=input_is_null, input_length=input_length)
    if parsed is None:
        return INVALID_RESULT
    _n, minimum_length, data = parsed

    # Every valid average lies in [-1000,1000]. The low endpoint is feasible;
    # the extra high endpoint is a known-false sentinel for upper-bound search.
    low = MIN_RESULT
    high = MAX_RESULT + 1
    while high - low > 1:
        middle = (low + high) // 2
        if _feasible(data, minimum_length, middle):
            low = middle
        else:
            high = middle
    return low
