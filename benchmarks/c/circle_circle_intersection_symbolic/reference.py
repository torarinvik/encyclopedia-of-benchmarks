"""Symbolic circle-circle reference; unexecuted draft."""
import struct


def expected_output(values, capacity=None, output_is_null=False,
                    input_is_null=False, input_length=None):
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (tuple, list)) or len(values) != 6
            or (input_length is not None and (type(input_length) is not int or input_length != 6))
            or any(type(v) is not int or not -1000 <= v <= 1000 for v in values)):
        return -1, b""
    x1, y1, r1, x2, y2, r2 = values
    if r1 < 1 or r2 < 1:
        return -1, b""
    dx, dy = x2-x1, y2-y1
    d = dx*dx+dy*dy
    if d == 0:
        words = (3 if r1 == r2 else 0,)
    else:
        t = d+r1*r1-r2*r2
        h = 4*r1*r1*d-t*t
        if h < 0:
            words = (0,)
        else:
            den = 2*d
            words = (1 if h == 0 else 2, den*x1+dx*t, den*y1+dy*t, den, -dy, dx, h)
    data = struct.pack("<"+"q"*len(words), *words)
    cap = 56 if capacity is None else capacity
    if type(output_is_null) is not bool or type(cap) is not int or cap < 0 or output_is_null or cap < len(data):
        return -2, b""
    return len(data), data
