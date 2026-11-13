"""Flat-label reference for the bounded region-merging profile."""

from collections.abc import Sequence
from fractions import Fraction


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or capacity is not None and (type(capacity) is not int or capacity < 0)
            or input_length is not None and (type(input_length) is not int or not 0 <= input_length <= 74)
            or input_is_null or values is None or not isinstance(values, (list, tuple))
            or input_length is not None and input_length != len(values)):
        return -1, b""
    if not 4 <= len(values) <= 74 or any(type(x) is not int for x in values):
        return -1, b""
    height, width = values[:2]
    if not 1 <= height <= 6 or not 1 <= width <= 6:
        return -1, b""
    n = height * width
    if len(values) != 2 + 2*n:
        return -1, b""
    bounds, pixels = values[2:2+n], values[2+n:]
    if any(not 0 <= x <= 65535 for x in bounds) or any(not 0 <= x <= 255 for x in pixels):
        return -1, b""
    labels = list(range(n))
    for difference in range(256):
        for p in range(n):
            neighbors = []
            if p % width + 1 < width:
                neighbors.append(p + 1)
            if p + width < n:
                neighbors.append(p + width)
            for q in neighbors:
                if abs(pixels[p] - pixels[q]) != difference or labels[p] == labels[q]:
                    continue
                left = [i for i in range(n) if labels[i] == labels[p]]
                right = [i for i in range(n) if labels[i] == labels[q]]
                delta = Fraction(sum(pixels[i] for i in left), len(left)) - Fraction(sum(pixels[i] for i in right), len(right))
                if delta * delta <= bounds[len(left)-1] + bounds[len(right)-1]:
                    merged = min(labels[p], labels[q])
                    for i in left + right:
                        labels[i] = merged
    if output_is_null or capacity is not None and capacity < n:
        return -2, b""
    return n, bytes(labels)
