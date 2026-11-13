"""Bounded ordered region merging with externally supplied squared bounds."""

from collections.abc import Sequence

MAX_INPUT_LENGTH = 74
MAX_OUTPUT_BYTES = 36


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or capacity is not None and (type(capacity) is not int or capacity < 0)
            or input_length is not None and (type(input_length) is not int or not 0 <= input_length <= MAX_INPUT_LENGTH)
            or input_is_null or values is None or not isinstance(values, (tuple, list))
            or input_length is not None and input_length != len(values)):
        return -1, b""
    if not 4 <= len(values) <= MAX_INPUT_LENGTH or any(type(x) is not int for x in values):
        return -1, b""
    height, width = values[:2]
    if not 1 <= height <= 6 or not 1 <= width <= 6:
        return -1, b""
    n = height * width
    if len(values) != 2 + 2 * n:
        return -1, b""
    bounds, pixels = values[2:2+n], values[2+n:]
    if any(not 0 <= x <= 65535 for x in bounds) or any(not 0 <= x <= 255 for x in pixels):
        return -1, b""
    parent = list(range(n))
    sizes = [1] * n
    sums = list(pixels)
    minima = list(range(n))

    def root(x: int) -> int:
        while parent[x] != x:
            parent[x] = parent[parent[x]]
            x = parent[x]
        return x

    edges = []
    for p in range(n):
        if p % width + 1 < width:
            edges.append((abs(pixels[p] - pixels[p+1]), p, p+1))
        if p + width < n:
            edges.append((abs(pixels[p] - pixels[p+width]), p, p+width))
    for _, p, q in sorted(edges):
        a, b = root(p), root(q)
        if a == b:
            continue
        na, nb = sizes[a], sizes[b]
        delta = sums[a] * nb - sums[b] * na
        if delta * delta <= (bounds[na-1] + bounds[nb-1]) * na * na * nb * nb:
            if sizes[a] < sizes[b]:
                a, b = b, a
            parent[b] = a
            sizes[a] += sizes[b]
            sums[a] += sums[b]
            minima[a] = min(minima[a], minima[b])
    payload = bytes(minima[root(p)] for p in range(n))
    if output_is_null or capacity is not None and capacity < n:
        return -2, b""
    return n, payload
