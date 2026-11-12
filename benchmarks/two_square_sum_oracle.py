"""Independent bounded oracle for all ordered two-square representations."""

from math import isqrt

MAX_Q = 8
MAX_N = 10_000
MAX_PARSEABLE_INPUT_LENGTH = MAX_Q + 1
MAX_OUTPUT_BYTES = MAX_Q * (4 + 8 * (isqrt(MAX_N) + 1))


def expected_output(values, output_capacity=None, output_is_null=False,
                    input_is_null=False, input_length=None):
    """Return ``(result, bytes)`` for packed ``[Q, N_0, ..., N_(Q-1)]``."""
    if input_is_null or not isinstance(values, (list, tuple)):
        return -1, b""
    if input_length is None:
        input_length = len(values)
    if (type(input_length) is not int
            or input_length > MAX_PARSEABLE_INPUT_LENGTH
            or input_length != len(values) or not values):
        return -1, b""
    q = values[0]
    if type(q) is not int or not 1 <= q <= MAX_Q or len(values) != q + 1:
        return -1, b""
    queries = values[1:]
    if any(type(n) is not int or not 0 <= n <= MAX_N for n in queries):
        return -1, b""

    records = []
    required = 0
    for n in queries:
        pairs = []
        for a in range(isqrt(n) + 1):
            b = isqrt(n - a * a)
            if b * b == n - a * a:
                pairs.append((a, b))
        records.append(pairs)
        required += 4 * (1 + 2 * len(pairs))

    capacity = MAX_OUTPUT_BYTES if output_capacity is None else output_capacity
    if (type(output_is_null) is not bool or type(capacity) is not int
            or capacity < 0):
        return -2, b""
    if output_is_null or capacity < required:
        return -2, b""

    output = bytearray()
    for pairs in records:
        output.extend(len(pairs).to_bytes(4, "little"))
        for a, b in pairs:
            output.extend(a.to_bytes(4, "little"))
            output.extend(b.to_bytes(4, "little"))
    result = bytes(output)
    return len(result), result
