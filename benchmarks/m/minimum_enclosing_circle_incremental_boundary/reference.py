"""Exact exhaustive support-circle reference; unexecuted draft."""
from fractions import Fraction
from itertools import combinations


def expected_output(values, capacity=64, output_is_null=False,
                    input_is_null=False, input_length=None):
    if (input_is_null or not isinstance(values, (tuple, list))
            or (input_length is not None and input_length != len(values))
            or not 4 <= len(values) <= 194
            or any(type(v) is not int for v in values)):
        return -1, b""
    n = values[0]
    if not 1 <= n <= 64 or len(values) != 1 + 3*n:
        return -1, b""
    coords = values[1:1+2*n]
    order = values[1+2*n:]
    if any(not -100 <= v <= 100 for v in coords) or sorted(order) != list(range(n)):
        return -1, b""
    if output_is_null or capacity < n:
        return -2, b""
    points = list(zip(coords[::2], coords[1::2]))
    unique_points = sorted(set(points))
    candidates = [(Fraction(x), Fraction(y), Fraction(0)) for x, y in unique_points]
    for (x1, y1), (x2, y2) in combinations(unique_points, 2):
        cx, cy = Fraction(x1+x2, 2), Fraction(y1+y2, 2)
        candidates.append((cx, cy, (cx-x1)**2 + (cy-y1)**2))
    for (x1, y1), (x2, y2), (x3, y3) in combinations(unique_points, 3):
        determinant = 2*(x1*(y2-y3) + x2*(y3-y1) + x3*(y1-y2))
        if determinant == 0:
            continue
        a, b, c = x1*x1+y1*y1, x2*x2+y2*y2, x3*x3+y3*y3
        cx = Fraction(a*(y2-y3) + b*(y3-y1) + c*(y1-y2), determinant)
        cy = Fraction(a*(x3-x2) + b*(x1-x3) + c*(x2-x1), determinant)
        candidates.append((cx, cy, (cx-x1)**2 + (cy-y1)**2))
    enclosing = ((r2, cx, cy) for cx, cy, r2 in candidates
                 if all((x-cx)**2 + (y-cy)**2 <= r2 for x, y in unique_points))
    r2, cx, cy = min(enclosing)
    return n, bytes(int((x-cx)**2 + (y-cy)**2 == r2) for x, y in points)
