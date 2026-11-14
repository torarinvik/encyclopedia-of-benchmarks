"""Bounded two-buckets-per-size exponential histogram reference draft."""

import struct


def expected_output(values, capacity=None, output_is_null=False, input_is_null=False, input_length=None):
    if (input_is_null or not isinstance(values, (tuple, list))
            or input_length is not None and input_length != len(values)
            or len(values) < 2 or any(type(value) is not int for value in values)):
        return -1, b""
    window, n = values[:2]
    if (not (1 <= window <= 64 and 0 <= n <= 128 and len(values) == 2+n)
            or any(bit not in (0, 1) for bit in values[2:])):
        return -1, b""
    buckets = []  # chronological (newest one timestamp, number of ones)
    estimates = []
    for timestamp, bit in enumerate(values[2:]):
        buckets = [(end, size) for end, size in buckets if end > timestamp-window]
        if bit:
            buckets.append((timestamp, 1))
        size = 1
        while size <= 128:
            indices = [i for i, bucket in enumerate(buckets) if bucket[1] == size]
            if len(indices) > 2:
                older, newer = indices[:2]
                buckets[newer] = (buckets[newer][0], 2*size)
                del buckets[older]
            size *= 2
        estimates.append(2*sum(size for _, size in buckets) - (buckets[0][1] if buckets else 0))
    payload = b"".join(struct.pack("<q", value) for value in estimates)
    if output_is_null or capacity is not None and capacity < len(payload):
        return -2, b""
    return len(payload), payload
