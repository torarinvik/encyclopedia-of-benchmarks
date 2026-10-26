"""Segment-tree-of-sorted-y-catalog oracle for bounded 2D range reporting."""

from __future__ import annotations

import struct
from collections.abc import Sequence

MAX_POINTS = 8
MAX_QUERIES = 8
MAX_INPUT = 50
MAX_OUTPUT_BYTES = 584


def _catalog_report(catalog: list[int], points: list[tuple[int, int]],
                    y_low: int, y_high: int) -> list[int]:
    lower, upper = 0, len(catalog)
    while lower < upper:
        middle = (lower + upper) // 2
        if points[catalog[middle]][1] < y_low:
            lower = middle + 1
        else:
            upper = middle
    first = lower
    lower, upper = first, len(catalog)
    while lower < upper:
        middle = (lower + upper) // 2
        if points[catalog[middle]][1] <= y_high:
            lower = middle + 1
        else:
            upper = middle
    return catalog[first:lower]


def _tree_report(points: list[tuple[int, int]], queries: list[tuple[int, int, int, int]]) -> list[list[int]]:
    base = 8
    by_x = sorted(range(len(points)), key=lambda point_id: (points[point_id][0], points[point_id][1], point_id))
    catalogs: list[list[int]] = [[] for _ in range(2 * base)]
    for rank, point_id in enumerate(by_x):
        catalogs[base + rank] = [point_id]
    for node in range(base - 1, 0, -1):
        left, right = catalogs[node * 2], catalogs[node * 2 + 1]
        catalogs[node] = sorted(left + right, key=lambda point_id: (points[point_id][1], point_id))
    results: list[list[int]] = []
    for x_low, x_high, y_low, y_high in queries:
        left = next((rank for rank, point_id in enumerate(by_x) if points[point_id][0] >= x_low), len(points))
        right = next((rank for rank, point_id in enumerate(by_x) if points[point_id][0] > x_high), len(points))
        hits: list[int] = []
        left += base
        right += base
        while left < right:
            if left & 1:
                hits.extend(_catalog_report(catalogs[left], points, y_low, y_high))
                left += 1
            if right & 1:
                right -= 1
                hits.extend(_catalog_report(catalogs[right], points, y_low, y_high))
            left //= 2
            right //= 2
        results.append(sorted(hits))
    return results


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or capacity is not None and (type(capacity) is not int or capacity < 0)
            or input_length is not None and (type(input_length) is not int or not 0 <= input_length <= MAX_INPUT)):
        return -1, b""
    if input_is_null or values is None or not isinstance(values, (list, tuple)):
        if input_is_null and values not in (None, [], ()):
            return -1, b""
        return -1, b""
    if input_length is not None and input_length != len(values):
        return -1, b""
    if not 2 <= len(values) <= MAX_INPUT or any(type(value) is not int or not -(1 << 63) <= value <= (1 << 63) - 1 for value in values):
        return -1, b""
    n, q = values[0], values[1]
    if not 1 <= n <= MAX_POINTS or not 1 <= q <= MAX_QUERIES or len(values) != 2 + 2 * n + 4 * q:
        return -1, b""
    points = [(values[2 + 2 * i], values[3 + 2 * i]) for i in range(n)]
    if any(not 0 <= x <= 15 or not 0 <= y <= 15 for x, y in points) or len(set(points)) != n:
        return -1, b""
    start = 2 + 2 * n
    queries = [tuple(values[start + 4 * i:start + 4 * i + 4]) for i in range(q)]
    if any(not 0 <= low <= high <= 15 for x0, x1, y0, y1 in queries for low, high in ((x0, x1), (y0, y1))):
        return -1, b""
    results = _tree_report(points, queries)
    words = [q]
    for hits in results:
        words.append(len(hits))
        words.extend(hits)
    payload = struct.pack("<" + "q" * len(words), *words)
    if output_is_null or capacity is not None and capacity < len(payload):
        return -2, b""
    return len(payload), payload
