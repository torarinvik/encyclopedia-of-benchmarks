"""Strict per-query patience-sorting oracle for bounded static range LIS."""

import struct
from typing import Sequence

MAX_N = 128
MAX_Q = 32
MAX_VALID_INPUT_LENGTH = 2 + MAX_N + 2 * MAX_Q
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_INPUT_LENGTH = MAX_PARSEABLE_INPUT_LENGTH
MAX_OUTPUT_BYTES = 8 * MAX_Q
MAX_WORKSPACE_BYTES = 2048
INVALID_RESULT = -1
OUTPUT_ERROR = -2


def _lis_length(values: Sequence[int]) -> int:
    tails: list[int] = []
    for value in values:
        lo, hi = 0, len(tails)
        while lo < hi:
            mid = lo + (hi - lo) // 2
            if tails[mid] < value:
                lo = mid + 1
            else:
                hi = mid
        if lo == len(tails):
            tails.append(value)
        else:
            tails[lo] = value
    return len(tails)


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if (input_is_null or not isinstance(values, (list, tuple))
            or len(values) < 2 or len(values) > MAX_PARSEABLE_INPUT_LENGTH
            or (input_length is not None
                and (type(input_length) is not int or input_length != len(values)
                     or not 0 <= input_length <= MAX_PARSEABLE_INPUT_LENGTH))
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return -1, b""
    n, q = values[:2]
    if not 1 <= n <= MAX_N or not 1 <= q <= MAX_Q:
        return -1, b""
    if len(values) != 2 + n + 2 * q:
        return -1, b""
    permutation = values[2:2 + n]
    seen = [False] * n
    for item in permutation:
        if not 0 <= item < n or seen[item]:
            return -1, b""
        seen[item] = True
    queries = []
    offset = 2 + n
    for _ in range(q):
        left, right = values[offset:offset + 2]
        offset += 2
        if not 0 <= left <= right <= n:
            return -1, b""
        queries.append((left, right))

    effective_capacity = MAX_OUTPUT_BYTES if capacity is None else capacity
    if (type(output_is_null) is not bool or type(effective_capacity) is not int
            or effective_capacity < 0):
        return -2, b""
    if output_is_null or effective_capacity < 8 * q:
        return -2, b""
    answers = [_lis_length(permutation[left:right]) for left, right in queries]
    payload = b"".join(struct.pack("<q", answer) for answer in answers)
    return len(payload), payload
