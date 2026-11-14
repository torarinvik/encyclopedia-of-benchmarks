"""Group/retry reference with linear tangent scans; not the benchmark kernel."""

import struct

from .independent_oracle import expected_output as validate_and_reference


def expected_output(values, capacity=None, output_is_null=False, input_is_null=False,
                    input_length=None):
    validation, _ = validate_and_reference(values, input_is_null=input_is_null,
                                            input_length=input_length)
    if validation < 0:
        return -1, b""
    if (type(output_is_null) is not bool
            or capacity is not None and (type(capacity) is not int or capacity < 0)):
        return -1, b""
    n = values[0]
    points = list(zip(values[1::2], values[2::2]))

    def cross(a, b, c):
        return (b[0]-a[0])*(c[1]-a[1]) - (b[1]-a[1])*(c[0]-a[0])

    def group_hull(group):
        ordered = sorted(group)
        if len(ordered) <= 1:
            return ordered
        lower, upper = [], []
        for point in ordered:
            while len(lower) >= 2 and cross(lower[-2], lower[-1], point) <= 0:
                lower.pop()
            lower.append(point)
        for point in reversed(ordered):
            while len(upper) >= 2 and cross(upper[-2], upper[-1], point) <= 0:
                upper.pop()
            upper.append(point)
        return lower[:-1] + upper[:-1]

    start = min(points)
    guess = min(4, n)
    while True:
        groups = [group_hull(points[i:i+guess]) for i in range(0, n, guess)]
        hull = [start]
        for _ in range(guess):
            current = hull[-1]
            candidate = None
            for group in groups:
                local = None
                for point in group:
                    if point == current:
                        continue
                    if local is None or cross(current, local, point) < 0:
                        local = point
                if local is not None and (candidate is None or cross(current, candidate, local) < 0):
                    candidate = local
            if candidate == start:
                words = [coordinate for point in hull for coordinate in point]
                payload = struct.pack("<" + "q" * len(words), *words)
                if output_is_null or capacity is not None and capacity < len(payload):
                    return -2, b""
                return len(payload), payload
            if candidate is None:
                raise ValueError("grouped hull failed to choose a successor")
            hull.append(candidate)
        if guess == n:
            raise ValueError("grouped hull did not close within n steps")
        guess = min(guess * guess, n)
