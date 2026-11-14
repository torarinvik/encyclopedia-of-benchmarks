"""Phase-oriented reference for the bounded Sticky Sampling replay."""

import struct


def expected_output(values, capacity=None, output_is_null=False, input_is_null=False, input_length=None):
    if (input_is_null or not isinstance(values, (tuple, list))
            or input_length is not None and input_length != len(values)
            or len(values) < 3 or any(type(value) is not int for value in values)):
        return -1, b""
    phase_unit, stream_length, tape_length = values[:3]
    if not (1 <= phase_unit <= 8 and 0 <= stream_length <= 64 and 0 <= tape_length <= 256
            and len(values) == 3 + stream_length + tape_length):
        return -1, b""
    stream = values[3:3 + stream_length]
    tape = values[3 + stream_length:]
    if any(not 0 <= item <= 15 for item in stream) or any(not 0 <= draw <= 255 for draw in tape):
        return -1, b""

    entries = {}
    cursor, start, rate, phase_length = 0, 0, 1, 2 * phase_unit
    while start < stream_length:
        if start:
            rate *= 2
            phase_length = rate * phase_unit
            for key in sorted(entries):
                count = entries[key]
                while count > 0:
                    if cursor >= tape_length:
                        return -1, b""
                    draw = tape[cursor]
                    cursor += 1
                    if draw % 2 == 1:
                        break
                    count -= 1
                if count:
                    entries[key] = count
                else:
                    del entries[key]
        end = min(start + phase_length, stream_length)
        for item in stream[start:end]:
            if item in entries:
                entries[item] += 1
            else:
                if cursor >= tape_length:
                    return -1, b""
                draw = tape[cursor]
                cursor += 1
                if draw % rate == 0:
                    entries[item] = 1
        start = end
    if cursor != tape_length:
        return -1, b""
    words = [len(entries)]
    for item, count in sorted(entries.items()):
        words.extend((item, count))
    payload = b"".join(struct.pack("<q", word) for word in words)
    if output_is_null or capacity is not None and capacity < len(payload):
        return -2, b""
    return len(payload), payload
