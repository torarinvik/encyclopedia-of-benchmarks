"""Backward last-writer reference for bounded Algorithm R."""

import struct


def expected_output(values, capacity=None, output_is_null=False, input_is_null=False, input_length=None):
    if input_is_null or not isinstance(values, (list, tuple)) or (input_length is not None and input_length != len(values)) or len(values) < 2:
        return -1, b""
    n, k = values[:2]
    if not (0 <= k <= n <= 64 and len(values) == 2+2*n-k):
        return -1, b""
    stream, draws = values[2:2+n], values[2+n:]
    if any(x < -1_000_000 or x > 1_000_000 for x in stream) or any(d < 0 or d > i for i, d in enumerate(draws, k)):
        return -1, b""
    if output_is_null or (capacity is not None and capacity < 8*k):
        return -2, b""
    result = []
    for slot in range(k):
        index = slot
        for i in range(n-1, k-1, -1):
            if draws[i-k] == slot:
                index = i
                break
        result.append(stream[index])
    return 8*k, b"".join(struct.pack("<q", x) for x in result)
