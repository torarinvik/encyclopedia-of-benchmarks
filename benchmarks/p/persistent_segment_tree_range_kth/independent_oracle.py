"""Independent range-kth oracle using direct slice sorting."""

from __future__ import annotations

MAX_N = 32
MAX_Q = 32
VALUE_MIN = -1000
VALUE_MAX = 1000
MAX_VALID_INPUT_LENGTH = 130
MAX_PARSEABLE_INPUT_LENGTH = 131
WORKSPACE_BYTES = 4096
INVALID_RESULT = -(1 << 63)


def expected_result(values, input_is_null=False, input_length=None):
    if input_is_null or not isinstance(values, (list, tuple)):
        return INVALID_RESULT
    if (not 2 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return INVALID_RESULT
    if input_length is not None and (
        type(input_length) is not int or input_length != len(values)
    ):
        return INVALID_RESULT
    n, q = values[0], values[1]
    if not 1 <= n <= MAX_N or not 0 <= q <= MAX_Q:
        return INVALID_RESULT
    if len(values) != 2 + n + 3 * q:
        return INVALID_RESULT
    sequence = values[2:2 + n]
    if any(value < VALUE_MIN or value > VALUE_MAX for value in sequence):
        return INVALID_RESULT
    checksum = 0
    offset = 2 + n
    for query_index in range(q):
        left, right, k = values[offset + 3 * query_index:offset + 3 * query_index + 3]
        if not (0 <= left <= right < n and 1 <= k <= right - left + 1):
            return INVALID_RESULT
        answer = sorted(sequence[left:right + 1])[k - 1]
        checksum += (query_index + 1) * answer
    return checksum
