"""Exact symbolic circle-line reference; unexecuted draft."""
import struct


def expected_output(values, capacity=None, output_is_null=False,
                    input_is_null=False, input_length=None):
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (tuple, list)) or len(values) != 6
            or input_length is not None and (type(input_length) is not int or input_length != len(values))
            or any(type(v) is not int or not -1000 <= v <= 1000 for v in values)):
        return -1, b""
    cx, cy, radius, a, b, c = values
    if radius < 1 or (a == 0 and b == 0):
        return -1, b""
    # Substituting (x,y)=(0,-c/b)+t*(b,-a), or the analogous
    # vertical-line parameterization, gives this discriminant after scaling.
    d = a*a + b*b
    q = a*cx + b*cy + c
    discriminant_quarter = radius*radius*d - q*q
    if discriminant_quarter < 0:
        words = (0,)
    else:
        words = (1 if discriminant_quarter == 0 else 2,
                 cx*d-a*q, cy*d-b*q, d, -b, a, discriminant_quarter)
    data = struct.pack("<" + "q" * len(words), *words)
    cap = 56 if capacity is None else capacity
    if type(output_is_null) is not bool or type(cap) is not int or cap < 0 or output_is_null or cap < len(data):
        return -2, b""
    return len(data), data
