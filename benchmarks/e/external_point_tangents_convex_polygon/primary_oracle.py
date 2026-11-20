"""Primary reference for logarithmic tangents from an external point."""

from __future__ import annotations

import struct

MAX_VERTICES = 32
MAX_QUERIES = 16
MAX_COORDINATE = 1000
MAX_INPUT_LENGTH = 98
MAX_PARSEABLE_INPUT_LENGTH = 99
MAX_OUTPUT_BYTES = 256
WORKSPACE_BYTES = 16_384

Point = tuple[int, int]


def cross(a: Point, b: Point) -> int:
    return a[0] * b[1] - a[1] * b[0]


def sub(a: Point, b: Point) -> Point:
    return a[0] - b[0], a[1] - b[1]


def valid_polygon(poly: list[Point]) -> bool:
    n = len(poly)
    if not 3 <= n <= MAX_VERTICES:
        return False
    for i, a in enumerate(poly):
        b = poly[(i + 1) % n]
        if a == b:
            return False
        edge = sub(b, a)
        for j, point in enumerate(poly):
            if j != i and j != (i + 1) % n and cross(edge, sub(point, a)) <= 0:
                return False
    return True


def valid_query(poly: list[Point], q: Point) -> bool:
    outside = False
    for i, a in enumerate(poly):
        side = cross(sub(poly[(i + 1) % len(poly)], a), sub(q, a))
        if side == 0:
            return False
        if side < 0:
            outside = True
    return outside


def _walk(poly: list[Point], start: int, stop: int) -> list[int]:
    chain = [start]
    while chain[-1] != stop:
        chain.append((chain[-1] + 1) % len(poly))
        if len(chain) > len(poly):
            return []
    return chain


def _split_ascending(poly: list[Point], chain: list[int], qx: int) -> int:
    lo, hi = 0, len(chain)
    while lo < hi:
        mid = (lo + hi) // 2
        if poly[chain[mid]][0] < qx:
            lo = mid + 1
        else:
            hi = mid
    return max(0, lo - 1)


def _split_descending(poly: list[Point], chain: list[int], qx: int) -> int:
    lo, hi = 0, len(chain)
    while lo < hi:
        mid = (lo + hi) // 2
        if poly[chain[mid]][0] > qx:
            lo = mid + 1
        else:
            hi = mid
    return max(0, lo - 1)


def _tangent_search(poly: list[Point], chain: list[int], lo: int, hi: int,
                    q: Point, sign: int) -> int:
    result = lo
    while lo <= hi:
        mid = (lo + hi) // 2
        index = chain[mid]
        here = sub(poly[index], q)
        next_point = sub(poly[(index + 1) % len(poly)], q)
        prev_point = sub(poly[(index - 1) % len(poly)], q)
        to_next = sign * cross(here, next_point)
        to_prev = sign * cross(here, prev_point)
        if to_next >= 0 and to_prev >= 0:
            return mid
        if to_next >= 0:
            result = mid
            hi = mid - 1
        else:
            lo = mid + 1
    return result


def _supports(poly: list[Point], index: int, q: Point, sign: int) -> bool:
    here = sub(poly[index], q)
    prev_point = sub(poly[(index - 1) % len(poly)], q)
    next_point = sub(poly[(index + 1) % len(poly)], q)
    return sign * cross(here, prev_point) > 0 and sign * cross(here, next_point) > 0


def build_layers(poly: list[Point]) -> tuple[list[int], list[int]] | None:
    """Build the polygon's two x-monotone chains once for all queries."""
    n = len(poly)
    left_x = min(p[0] for p in poly)
    right_x = max(p[0] for p in poly)
    left_ids = [i for i, p in enumerate(poly) if p[0] == left_x]
    right_ids = [i for i, p in enumerate(poly) if p[0] == right_x]
    left_bottom = min(left_ids, key=lambda i: poly[i][1])
    left_top = max(left_ids, key=lambda i: poly[i][1])
    right_bottom = min(right_ids, key=lambda i: poly[i][1])
    right_top = max(right_ids, key=lambda i: poly[i][1])
    lower = _walk(poly, left_bottom, right_bottom)
    upper = _walk(poly, right_top, left_top)
    if not lower or not upper:
        return None
    return lower, upper


def tangent_ids(poly: list[Point], lower: list[int], upper: list[int],
                q: Point) -> tuple[int, int] | None:
    """Return the two original vertex IDs, using six binary searches."""
    n = len(poly)

    # Six searches: one split for each x-monotone chain, then two tangent
    # searches on each chain. The contact checks select the valid candidates.
    lower_split = _split_ascending(poly, lower, q[0])
    upper_split = _split_descending(poly, upper, q[0])
    left_candidates = [
        lower[_tangent_search(poly, lower, 0, lower_split, q, -1)],
        upper[_tangent_search(poly, upper, 0, upper_split, q, -1)],
    ]
    right_candidates = [
        lower[_tangent_search(poly, lower, lower_split, len(lower) - 1, q, 1)],
        upper[_tangent_search(poly, upper, upper_split, len(upper) - 1, q, 1)],
    ]
    left = next((i for i in left_candidates if _supports(poly, i, q, -1)), None)
    right = next((i for i in right_candidates if _supports(poly, i, q, 1)), None)
    if left is None or right is None or left == right:
        return None
    return tuple(sorted((left, right)))


def expected_output(values: list[int] | None, output_capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if input_is_null or values is None:
        return -1, b""
    length = len(values) if input_length is None else input_length
    if length != len(values) or length < 2 or length > MAX_PARSEABLE_INPUT_LENGTH:
        return -1, b""
    if any(not isinstance(x, int) or x < -(1 << 63) or x >= (1 << 63) for x in values):
        return -1, b""
    n, q_count = values[0], values[1]
    if not (3 <= n <= MAX_VERTICES and 0 <= q_count <= MAX_QUERIES):
        return -1, b""
    if length != 2 + 2 * n + 2 * q_count:
        return -1, b""
    at = 2
    polygon = []
    for _ in range(n):
        x, y = values[at], values[at + 1]
        at += 2
        if not (-MAX_COORDINATE <= x <= MAX_COORDINATE and -MAX_COORDINATE <= y <= MAX_COORDINATE):
            return -1, b""
        polygon.append((x, y))
    if not valid_polygon(polygon):
        return -1, b""
    layers = build_layers(polygon)
    if layers is None:
        return -1, b""
    lower, upper = layers
    queries = []
    for _ in range(q_count):
        x, y = values[at], values[at + 1]
        at += 2
        if not (-MAX_COORDINATE <= x <= MAX_COORDINATE and -MAX_COORDINATE <= y <= MAX_COORDINATE):
            return -1, b""
        query = (x, y)
        if not valid_query(polygon, query):
            return -1, b""
        pair = tangent_ids(polygon, lower, upper, query)
        if pair is None:
            return -1, b""
        queries.extend(pair)

    needed = 8 * len(queries)
    capacity = MAX_OUTPUT_BYTES if output_capacity is None else output_capacity
    if (type(output_is_null) is not bool or type(capacity) is not int
            or capacity < needed or output_is_null):
        return -2, b""
    return needed, b"".join(struct.pack("<q", value) for value in queries)
