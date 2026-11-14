"""Class/offset reference for bounded rank and select queries."""

import struct


def expected_output(values, capacity=None, output_is_null=False, input_is_null=False, input_length=None):
    if (type(input_is_null) is not bool or type(output_is_null) is not bool
            or capacity is not None and (type(capacity) is not int or capacity < 0)
            or input_is_null or not isinstance(values, (list, tuple))
            or input_length is not None and (type(input_length) is not int or input_length != len(values))
            or len(values) < 3 or len(values) > 36
            or any(type(x) is not int or not -(1 << 63) <= x < (1 << 63) for x in values)):
        return -1, b""
    n, bits, q = values[:3]
    if not (1 <= n <= 63 and bits >= 0 and bits >> n == 0 and 0 <= q <= 16 and len(values) == 3 + 2*q):
        return -1, b""
    for i in range(q):
        op, index = values[3+2*i:5+2*i]
        if op not in (0, 1) or index < 1 or (op == 0 and index > n) or (op == 1 and index > 64):
            return -1, b""
    if output_is_null or (capacity is not None and capacity < 8*q):
        return -2, b""
    classes, offsets, prefix = [], [], [0]
    for block in range((n+7)//8):
        byte = (bits >> (8*block)) & 255
        cls = byte.bit_count()
        classes.append(cls)
        offsets.append(sum(x.bit_count() == cls for x in range(byte)))
        prefix.append(prefix[-1] + cls)

    def decode(block):
        offset = offsets[block]
        for candidate in range(256):
            if candidate.bit_count() == classes[block]:
                if offset == 0:
                    return candidate
                offset -= 1
        raise ValueError("invalid class/offset")

    answers = []
    for i in range(q):
        op, index = values[3+2*i:5+2*i]
        if op == 0:
            block = (index-1)//8
            byte = decode(block)
            answer = prefix[block] + sum((byte >> bit) & 1 for bit in range(index-8*block))
        else:
            block = 0
            while block < len(classes) and prefix[block+1] < index:
                block += 1
            answer = -1
            if block < len(classes):
                remaining = index-prefix[block]
                byte = decode(block)
                for bit in range(min(8, n-8*block)):
                    if (byte >> bit) & 1:
                        remaining -= 1
                        if remaining == 0:
                            answer = 8*block+bit+1
                            break
        answers.append(answer)
    return 8*q, b"".join(struct.pack("<q", answer) for answer in answers)
