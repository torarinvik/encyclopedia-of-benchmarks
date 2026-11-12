"""Period-block oracle for the bounded Library Checker run-enumeration profile."""

import struct

MAX_N = 24
MAX_PARSEABLE_INPUT_LENGTH = MAX_N + 1
MAX_RUNS_BOUND = (MAX_N // 2) * (MAX_N - MAX_N // 2)
MAX_OUTPUT_BYTES = 8 * (1 + 3 * MAX_RUNS_BOUND)
INVALID_RESULT = -1
OUTPUT_ERROR = -2


def _runs(text):
    n = len(text)
    lcp = [[0] * (n + 1) for _ in range(n + 1)]
    for left in range(n - 1, -1, -1):
        for right in range(n - 1, left, -1):
            if text[left] == text[right]:
                lcp[left][right] = 1 + lcp[left + 1][right + 1]

    found = []
    for period in range(1, n // 2 + 1):
        index = period
        while index < n:
            if text[index] != text[index - period]:
                index += 1
                continue
            first = index
            while index < n and text[index] == text[index - period]:
                index += 1
            last = index - 1
            left = first - period
            right = last + 1
            if right - left < 2 * period:
                continue
            minimal = True
            for smaller in range(1, period):
                if lcp[left][left + smaller] >= right - left - smaller:
                    minimal = False
                    break
            if minimal:
                found.append((period, left, right))
    found.sort()
    return found


def _encode(runs):
    output = bytearray(struct.pack("<q", len(runs)))
    for period, left, right in runs:
        output.extend(struct.pack("<qqq", period, left, right))
    return bytes(output)


def expected_output(values, capacity=None, output_is_null=False,
                    input_is_null=False, input_length=None):
    """Return ``(result, bytes)`` for ``[n, lowercase letter codes...]``."""
    if input_is_null or not isinstance(values, (list, tuple)):
        return INVALID_RESULT, b""
    if input_length is None:
        input_length = len(values)
    if (type(input_length) is not int or input_length < 2
            or input_length > MAX_PARSEABLE_INPUT_LENGTH
            or input_length != len(values)
            or any(type(value) is not int for value in values)):
        return INVALID_RESULT, b""
    n = values[0]
    if not 1 <= n <= MAX_N or len(values) != n + 1:
        return INVALID_RESULT, b""
    text = values[1:]
    if any(not 0 <= value < 26 for value in text):
        return INVALID_RESULT, b""

    runs = _runs(text)
    output = _encode(runs)
    if type(output_is_null) is not bool:
        return OUTPUT_ERROR, b""
    effective_capacity = MAX_OUTPUT_BYTES if capacity is None else capacity
    if type(effective_capacity) is not int or effective_capacity < 0:
        return OUTPUT_ERROR, b""
    if output_is_null or effective_capacity < len(output):
        return OUTPUT_ERROR, b""
    return len(output), output
