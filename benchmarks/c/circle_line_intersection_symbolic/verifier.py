"""Quadratic line-parameter reference; unexecuted draft."""
from fractions import Fraction
import struct


def expected_output(values, capacity=None, output_is_null=False,
                    input_is_null=False, input_length=None):
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (tuple, list)) or len(values) != 6
            or (input_length is not None and (type(input_length) is not int or input_length != 6))
            or any(type(v) is not int or not -1000 <= v <= 1000 for v in values)):
        return -1, b""
    x, y, r, a, b, c = values
    if r < 1 or (a == 0 and b == 0):
        return -1, b""
    # Substitute P+t*(-b,a) into the circle equation; P is any point on the line.
    px, py = (Fraction(-c, a), Fraction(0)) if a else (Fraction(0), Fraction(-c, b))
    vx, vy = -b, a
    norm = vx*vx + vy*vy
    linear_half = (px-x)*vx + (py-y)*vy
    constant = (px-x)**2 + (py-y)**2 - r*r
    quarter_discriminant = linear_half**2 - norm*constant
    if quarter_discriminant < 0:
        words = (0,)
    else:
        midpoint = -linear_half / norm
        fx = (px + midpoint*vx)*norm
        fy = (py + midpoint*vy)*norm
        assert fx.denominator == fy.denominator == quarter_discriminant.denominator == 1
        words = (1 if quarter_discriminant == 0 else 2, int(fx), int(fy),
                 norm, vx, vy, int(quarter_discriminant))
    data = struct.pack("<" + "q"*len(words), *words)
    cap = 56 if capacity is None else capacity
    if type(output_is_null) is not bool or type(cap) is not int or cap < 0 or output_is_null or cap < len(data):
        return -2, b""
    return len(data), data
