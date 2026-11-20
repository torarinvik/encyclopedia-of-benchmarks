"""Direct interval scans for the constant-time Sqrt Tree output contract."""

from __future__ import annotations

MAX_ITEMS = 64
MAX_QUERIES = 64
VALUE_LIMIT = 1_000_000_000
INVALID_RESULT = -1
MAX_VALID_INPUT_LENGTH = 194
MAX_PARSEABLE_INPUT_LENGTH = 195
MAX_OUTPUT_BYTES = 512
MAX_WORKSPACE_BYTES = 8192


def _valid(values, input_is_null=False, input_length=None):
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
    n, q = values[:2]
    if not 1 <= n <= MAX_ITEMS or not 0 <= q <= MAX_QUERIES:
        return None
    if len(values) != 2 + n + 2 * q:
        return None
    array = values[2:2 + n]
    if any(x < -VALUE_LIMIT or x > VALUE_LIMIT for x in array):
        return None
    queries = []
    for i in range(2 + n, len(values), 2):
        left, right = values[i], values[i + 1]
        if not (0 <= left <= right < n):
            return None
        queries.append((left, right))
    return array, queries


def expected_output(values, input_is_null=False, input_length=None):
    parsed = _valid(values, input_is_null=input_is_null, input_length=input_length)
    if parsed is None:
        return b""
    array, queries = parsed
    output = bytearray()
    for left, right in queries:
        minimum = array[left]
        for index in range(left + 1, right + 1):
            if array[index] < minimum:
                minimum = array[index]
        output.extend(minimum.to_bytes(8, "little", signed=True))
    return bytes(output)


def expected_result(values, input_is_null=False, input_length=None):
    parsed = _valid(values, input_is_null=input_is_null, input_length=input_length)
    return INVALID_RESULT if parsed is None else 8 * len(parsed[1])
