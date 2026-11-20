"""Enumeration-based colex oracle, independent of combinadic arithmetic."""

import struct

MAX_N = 16
MAX_K = 16
MAX_VALID_INPUT_LENGTH = 19
MAX_PARSEABLE_INPUT_LENGTH = 20
MAX_OUTPUT_BYTES = 136
WORKSPACE_BYTES = 1024


def _valid_word(value):
    return type(value) is int and -(1 << 63) <= value < (1 << 63)


def _colex_subsets(n, k):
    """Yield tuples by increasing largest element, recursively."""
    if k == 0:
        yield ()
        return
    for largest in range(k - 1, n):
        for prefix in _colex_subsets(largest, k - 1):
            yield prefix + (largest,)


def _serialize(rank, indices):
    return b"".join(struct.pack("<q", x) for x in (rank, *indices))


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
    if not 1 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH:
        return -1, b""
    if input_length is not None and input_length != len(values):
        return -1, b""
    if any(not _valid_word(word) for word in values):
        return -1, b""

    mode = values[0]
    if mode not in (0, 1) or len(values) < 3:
        return -1, b""
    n, k = values[1], values[2]
    if not 0 <= n <= MAX_N or not 0 <= k <= n:
        return -1, b""

    if mode == 0:
        if len(values) != 3 + k:
            return -1, b""
        target = tuple(values[3:])
        if any(not 0 <= item < n for item in target):
            return -1, b""
        if any(target[i - 1] >= target[i] for i in range(1, k)):
            return -1, b""
        rank = None
        for ordinal, subset in enumerate(_colex_subsets(n, k)):
            if subset == target:
                rank = ordinal
                break
        if rank is None:
            return -1, b""
        indices = target
    else:
        if len(values) != 4:
            return -1, b""
        requested = values[3]
        if requested < 0:
            return -1, b""
        indices = None
        for ordinal, subset in enumerate(_colex_subsets(n, k)):
            if ordinal == requested:
                indices = subset
                break
        if indices is None:
            return -1, b""
        rank = requested

    payload = _serialize(rank, indices)
    if output_is_null or (capacity is not None and capacity < len(payload)):
        return -2, b""
    return len(payload), payload
