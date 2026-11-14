"""Replayable, fixed-alphabet Sticky Sampling reference draft."""

import struct


def expected_output(values, capacity=None, output_is_null=False, input_is_null=False, input_length=None):
    if (input_is_null or not isinstance(values, (tuple, list))
            or (input_length is not None and input_length != len(values))
            or len(values) < 3 or any(type(value) is not int for value in values)):
        return -1, b""
    t, n, k = values[:3]
    if not (1 <= t <= 8 and 0 <= n <= 64 and 0 <= k <= 256 and len(values) == 3+n+k):
        return -1, b""
    items, draws = values[3:3+n], values[3+n:]
    if any(item < 0 or item > 15 for item in items) or any(draw < 0 or draw > 255 for draw in draws):
        return -1, b""
    counts = [0] * 16
    position, rate, phase_end = 0, 1, 2*t
    for index, item in enumerate(items):
        if index == phase_end:
            rate *= 2
            phase_end += rate*t
            for key in range(16):
                while counts[key]:
                    if position == k:
                        return -1, b""
                    draw = draws[position]
                    position += 1
                    if draw & 1:
                        break
                    counts[key] -= 1
        if counts[item]:
            counts[item] += 1
        else:
            if position == k:
                return -1, b""
            draw = draws[position]
            position += 1
            if draw % rate == 0:
                counts[item] = 1
    if position != k:
        return -1, b""
    words = [sum(count != 0 for count in counts)]
    for item, count in enumerate(counts):
        if count:
            words.extend((item, count))
    output = b"".join(struct.pack("<q", value) for value in words)
    if output_is_null or (capacity is not None and capacity < len(output)):
        return -2, b""
    return len(output), output
