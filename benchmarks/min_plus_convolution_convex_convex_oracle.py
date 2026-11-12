"""Direct bounded oracle for convex/convex min-plus convolution."""

import struct

MAX_N = 128
MAX_M = 128
MAX_VALUE = 1_000_000_000
MAX_VALID_INPUT_LENGTH = 2 + MAX_N + MAX_M
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_OUTPUT_ELEMENTS = MAX_N + MAX_M - 1
MAX_OUTPUT_BYTES = MAX_OUTPUT_ELEMENTS * 8
MAX_WORKSPACE_BYTES = MAX_OUTPUT_BYTES


def _parse(values, input_length=None):
    try:
        words = tuple(values)
    except TypeError:
        return None
    length = len(words) if input_length is None else input_length
    if (type(length) is not int or length < 4
            or length > MAX_PARSEABLE_INPUT_LENGTH or length != len(words)):
        return None
    n, m = words[:2]
    if (type(n) is not int or type(m) is not int
            or not 1 <= n <= MAX_N or not 1 <= m <= MAX_M
            or length != 2 + n + m):
        return None
    a = words[2:2 + n]
    b = words[2 + n:]
    if any(type(value) is not int or not 0 <= value <= MAX_VALUE for value in a + b):
        return None
    for sequence in (a, b):
        for index in range(len(sequence) - 2):
            if sequence[index + 1] - sequence[index] > sequence[index + 2] - sequence[index + 1]:
                return None
    return a, b


def evaluate(values, input_length=None):
    """Compute each output index by a direct O(NM) bounded scan."""
    parsed = _parse(values, input_length)
    if parsed is None:
        return -1, b""
    a, b = parsed
    output = []
    for index in range(len(a) + len(b) - 1):
        low = max(0, index - (len(a) - 1))
        high = min(len(b) - 1, index)
        best = min(a[index - j] + b[j] for j in range(low, high + 1))
        output.append(best)
    payload = b"".join(struct.pack("<q", value) for value in output)
    return len(payload), payload


def expected_output(values, capacity=None, output_is_null=False, input_is_null=False,
                    input_length=None):
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or capacity is not None and (type(capacity) is not int or capacity < 0)
            or input_length is not None and (type(input_length) is not int
                                             or not 0 <= input_length <= MAX_PARSEABLE_INPUT_LENGTH)):
        return -1, b""
    if input_is_null or values is None:
        return -1, b""
    try:
        actual_length = len(values)
    except TypeError:
        return -1, b""
    if input_length is not None and input_length != actual_length:
        return -1, b""
    result, payload = evaluate(values, actual_length)
    if result < 0:
        return result, payload
    if output_is_null or capacity is not None and capacity < result:
        return -2, b""
    return result, payload
