"""Per-size queue reference for bounded exponential-histogram counting."""

import struct


def expected_output(values, capacity=None, output_is_null=False, input_is_null=False, input_length=None):
    if (input_is_null or not isinstance(values, (tuple, list)) or len(values) < 2
            or input_length is not None and input_length != len(values)
            or any(type(value) is not int for value in values)):
        return -1, b""
    window, n = values[:2]
    if (not 1 <= window <= 64 or not 0 <= n <= 128 or len(values) != n+2
            or any(value not in (0, 1) for value in values[2:])):
        return -1, b""
    levels = [[] for _ in range(8)]
    results = []
    for time, bit in enumerate(values[2:]):
        for ends in levels:
            while ends and ends[0] <= time-window:
                ends.pop(0)
        if bit:
            levels[0].append(time)
        for level in range(7):
            if len(levels[level]) > 2:
                newer = levels[level][1]
                del levels[level][:2]
                levels[level+1].append(newer)
        total = sum((1 << level)*len(ends) for level, ends in enumerate(levels))
        oldest = min(((ends[0], 1 << level) for level, ends in enumerate(levels) if ends),
                     default=(0, 0))
        results.append(2*total-oldest[1])
    payload = b"".join(struct.pack("<q", result) for result in results)
    if output_is_null or capacity is not None and capacity < len(payload):
        return -2, b""
    return len(payload), payload
