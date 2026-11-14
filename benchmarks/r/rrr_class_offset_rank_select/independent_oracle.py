"""Direct bit-scan reference for the bounded RRR-style profile."""

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
    if not (1 <= n <= 63 and 0 <= bits and bits >> n == 0 and 0 <= q <= 16 and len(values) == 3 + 2*q):
        return -1, b""
    answers = []
    for i in range(q):
        op, index = values[3+2*i:5+2*i]
        if op == 0:
            if not 1 <= index <= n:
                return -1, b""
            answer = sum((bits >> j) & 1 for j in range(index))
        elif op == 1:
            if not 1 <= index <= 64:
                return -1, b""
            positions = [j+1 for j in range(n) if (bits >> j) & 1]
            answer = positions[index-1] if index <= len(positions) else -1
        else:
            return -1, b""
        answers.append(answer)
    if output_is_null or (capacity is not None and capacity < 8*q):
        return -2, b""
    return 8*q, b"".join(struct.pack("<q", answer) for answer in answers)
