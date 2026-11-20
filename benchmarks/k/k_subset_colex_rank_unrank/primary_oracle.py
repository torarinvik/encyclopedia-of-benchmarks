"""Combinadic rank and greedy colex unrank reference."""

import struct

MAX_N = 16
MAX_K = 16
MAX_VALID_INPUT_LENGTH = 19
MAX_PARSEABLE_INPUT_LENGTH = 20
MAX_OUTPUT_BYTES = 136
WORKSPACE_BYTES = 1024


def _is_i64(value):
    return type(value) is int and -(1 << 63) <= value < (1 << 63)


def _choose(n, k):
    if n < 0 or k < 0 or k > n:
        return 0
    k = min(k, n - k)
    result = 1
    for i in range(1, k + 1):
        result = result * (n - k + i) // i
    return result


def _rank(indices):
    result = 0
    for i, value in enumerate(indices):
        result += _choose(value, i + 1)
    return result


def _unrank(n, k, rank):
    indices = [0] * k
    upper = n - 1
    remainder = rank
    for order in range(k, 0, -1):
        candidate = upper
        while _choose(candidate, order) > remainder:
            candidate -= 1
        indices[order - 1] = candidate
        remainder -= _choose(candidate, order)
        upper = candidate - 1
    return indices


def _encode(words):
    return b"".join(struct.pack("<q", word) for word in words)


def expected_output(values, capacity=None, output_is_null=False,
                    input_is_null=False, input_length=None):
    if type(output_is_null) is not bool or type(input_is_null) is not bool:
        return -1, b""
    if capacity is not None and (type(capacity) is not int or capacity < 0):
        return -1, b""
    if input_length is not None and (type(input_length) is not int or input_length < 0):
        return -1, b""
    if input_is_null or not isinstance(values, (list, tuple)):
        return -1, b""
    length = len(values)
    if not 1 <= length <= MAX_PARSEABLE_INPUT_LENGTH:
        return -1, b""
    if input_length is not None and input_length != length:
        return -1, b""
    if any(not _is_i64(value) for value in values):
        return -1, b""

    mode = values[0]
    if mode not in (0, 1) or length < 3:
        return -1, b""
    n, k = values[1], values[2]
    if not 0 <= n <= MAX_N or not 0 <= k <= n:
        return -1, b""

    if mode == 0:
        if length != 3 + k:
            return -1, b""
        indices = list(values[3:])
        if any(not 0 <= x < n for x in indices):
            return -1, b""
        if any(indices[i - 1] >= indices[i] for i in range(1, k)):
            return -1, b""
        rank = _rank(indices)
    else:
        if length != 4:
            return -1, b""
        rank = values[3]
        if not 0 <= rank < _choose(n, k):
            return -1, b""
        indices = _unrank(n, k, rank)

    words = [rank, *indices]
    payload = _encode(words)
    if output_is_null or (capacity is not None and capacity < len(payload)):
        return -2, b""
    return len(payload), payload
