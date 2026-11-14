"""Dictionary-based reference for the bounded Lossy Counting snapshot."""

import struct


def expected_output(values, capacity=None, output_is_null=False, input_is_null=False, input_length=None):
    if input_is_null or not isinstance(values, (tuple, list)) or (input_length is not None and input_length != len(values)) or len(values) < 2:
        return -1, b""
    width, n = values[:2]
    if not (2 <= width <= 16 and 0 <= n <= 64 and len(values) == 2+n) or any(x < 0 or x > 15 for x in values[2:]):
        return -1, b""
    entries = {}
    for i, item in enumerate(values[2:]):
        bucket = i//width+1
        count, error = entries.get(item, (0, bucket-1))
        entries[item] = (count+1, error)
        if (i+1) % width == 0:
            entries = {key: pair for key, pair in entries.items() if sum(pair) > bucket}
    words = [len(entries)]
    for item in sorted(entries):
        words.extend((item, *entries[item]))
    payload = b"".join(struct.pack("<q", word) for word in words)
    if output_is_null or (capacity is not None and capacity < len(payload)):
        return -2, b""
    return len(payload), payload
