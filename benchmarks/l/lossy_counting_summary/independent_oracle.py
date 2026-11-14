"""Bucket-batched reference for bounded Lossy Counting."""

import struct


def expected_output(values, capacity=None, output_is_null=False, input_is_null=False, input_length=None):
    if input_is_null or not isinstance(values, (tuple, list)) or (input_length is not None and input_length != len(values)) or len(values) < 2:
        return -1, b""
    width, n = values[:2]
    if not (2 <= width <= 16 and 0 <= n <= 64 and len(values) == 2+n) or any(x < 0 or x > 15 for x in values[2:]):
        return -1, b""
    count = [0]*16
    error = [0]*16
    for start in range(0, n, width):
        bucket = start//width+1
        chunk = values[2+start:2+min(start+width, n)]
        for item in set(chunk):
            occurrences = sum(value == item for value in chunk)
            if count[item] == 0:
                error[item] = bucket-1
            count[item] += occurrences
        if len(chunk) == width:
            for item in range(16):
                if count[item] and count[item]+error[item] <= bucket:
                    count[item] = 0
                    error[item] = 0
    words = [sum(x != 0 for x in count)]
    for item in range(16):
        if count[item]:
            words.extend((item, count[item], error[item]))
    payload = b"".join(struct.pack("<q", word) for word in words)
    if output_is_null or (capacity is not None and capacity < len(payload)):
        return -2, b""
    return len(payload), payload
