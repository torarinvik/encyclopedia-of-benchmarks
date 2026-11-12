"""Angular range counting with one Fenwick tree per anchor point."""

from __future__ import annotations

from collections.abc import Sequence
from functools import cmp_to_key
import struct

MAX_N = 24
MAX_M = 24
MAX_Q = 128
COORD_LIMIT = 1_000_000_000
MAX_INPUT_LENGTH = 3 + 2 * MAX_N + 2 * MAX_M + 3 * MAX_Q
MAX_OUTPUT_BYTES = 8 * MAX_Q
MAX_WORKSPACE_BYTES = 65536
INVALID = -1
OUTPUT_ERROR = -2
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1


def _half(x: int, y: int) -> int:
    if y < 0:
        return 0
    if y == 0 and x >= 0:
        return 1
    return 2


def _angle_less(a: tuple[int, int], b: tuple[int, int]) -> bool:
    """Compare polar angles in [0, 2*pi), treating equal rays as equal."""
    ha, hb = _half(*a), _half(*b)
    if ha != hb:
        return ha < hb
    return a[0] * b[1] - a[1] * b[0] > 0


def _direction_compare(a: tuple[int, int], b: tuple[int, int]) -> int:
    if _angle_less(a, b):
        return -1
    if _angle_less(b, a):
        return 1
    ra, rb = a[0] * a[0] + a[1] * a[1], b[0] * b[0] + b[1] * b[1]
    if ra != rb:
        return -1 if ra < rb else 1
    return (a > b) - (a < b)


def _parse(values, input_is_null: bool, input_length: int | None):
    if input_is_null or not isinstance(values, (list, tuple)):
        return None
    if not 3 <= len(values) <= MAX_INPUT_LENGTH:
        return None
    if input_length is not None and (
        type(input_length) is not int or input_length != len(values)
    ):
        return None
    if any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values):
        return None
    n, m, q = values[:3]
    if not 1 <= n <= MAX_N or not 1 <= m <= MAX_M or not 1 <= q <= MAX_Q:
        return None
    expected_length = 3 + 2 * n + 2 * m + 3 * q
    if len(values) != expected_length:
        return None
    cursor = 3
    a_points = []
    for _ in range(n):
        x, y = values[cursor], values[cursor + 1]
        cursor += 2
        if abs(x) > COORD_LIMIT or abs(y) > COORD_LIMIT:
            return None
        a_points.append((x, y))
    b_points = []
    for _ in range(m):
        x, y = values[cursor], values[cursor + 1]
        cursor += 2
        if abs(x) > COORD_LIMIT or abs(y) > COORD_LIMIT:
            return None
        b_points.append((x, y))
    queries = []
    for _ in range(q):
        a, b, c = values[cursor], values[cursor + 1], values[cursor + 2]
        cursor += 3
        if not (0 <= a < n and 0 <= b < n and 0 <= c < n):
            return None
        queries.append((a, b, c))
    return a_points, b_points, queries


def _fenwick_add(tree: list[int], index: int, amount: int) -> None:
    index += 1
    while index < len(tree):
        tree[index] += amount
        index += index & -index


def _fenwick_prefix(tree: list[int], end: int) -> int:
    total = 0
    while end > 0:
        total += tree[end]
        end &= end - 1
    return total


def _lower_bound(directions: list[tuple[int, int]], ray: tuple[int, int]) -> int:
    low, high = 0, len(directions)
    while low < high:
        middle = (low + high) // 2
        if _angle_less(directions[middle], ray):
            low = middle + 1
        else:
            high = middle
    return low


def _upper_bound(directions: list[tuple[int, int]], ray: tuple[int, int]) -> int:
    low, high = 0, len(directions)
    while low < high:
        middle = (low + high) // 2
        if not _angle_less(ray, directions[middle]):
            low = middle + 1
        else:
            high = middle
    return low


def _count_arc(
    directions: list[tuple[int, int]], tree: list[int], start: tuple[int, int], end: tuple[int, int]
) -> int:
    left = _lower_bound(directions, start)
    right = _upper_bound(directions, end)
    if not _angle_less(end, start):
        return _fenwick_prefix(tree, right) - _fenwick_prefix(tree, left)
    return (
        _fenwick_prefix(tree, len(directions)) - _fenwick_prefix(tree, left)
        + _fenwick_prefix(tree, right)
    )


def _evaluate(a_points: list[tuple[int, int]], b_points: list[tuple[int, int]], queries):
    directions: list[list[tuple[int, int]]] = []
    fenwick: list[list[int]] = []
    zero_counts: list[int] = []
    for ax, ay in a_points:
        rays = []
        zeros = 0
        for bx, by in b_points:
            ray = (bx - ax, by - ay)
            if ray == (0, 0):
                zeros += 1
            else:
                rays.append(ray)
        rays.sort(key=cmp_to_key(_direction_compare))
        tree = [0] * (len(rays) + 1)
        for index in range(len(rays)):
            _fenwick_add(tree, index, 1)
        directions.append(rays)
        fenwick.append(tree)
        zero_counts.append(zeros)

    def arc(anchor: int, start: tuple[int, int], end: tuple[int, int]) -> int:
        return _count_arc(directions[anchor], fenwick[anchor], start, end)

    def halfplane(u: int, v: int) -> int:
        dx = a_points[v][0] - a_points[u][0]
        dy = a_points[v][1] - a_points[u][1]
        return zero_counts[u] + arc(u, (-dx, -dy), (dx, dy))

    answers = []
    for ia, ib, ic in queries:
        a, b, c = a_points[ia], a_points[ib], a_points[ic]
        orient = (b[0] - a[0]) * (c[1] - a[1]) - (b[1] - a[1]) * (c[0] - a[0])
        if orient == 0:
            answers.append(0)
            continue
        if orient < 0:
            ib, ic = ic, ib
            a, b, c = a_points[ia], a_points[ib], a_points[ic]

        outside_sum = halfplane(ia, ib) + halfplane(ib, ic) + halfplane(ic, ia)
        pair_sum = (
            zero_counts[ib] + arc(ib, (b[0] - c[0], b[1] - c[1]), (b[0] - a[0], b[1] - a[1]))
            + zero_counts[ic] + arc(ic, (c[0] - a[0], c[1] - a[1]), (c[0] - b[0], c[1] - b[1]))
            + zero_counts[ia] + arc(ia, (a[0] - b[0], a[1] - b[1]), (a[0] - c[0], a[1] - c[1]))
        )
        answers.append(len(b_points) - outside_sum + pair_sum)
    return answers


def expected_output(
    values: Sequence[int] | None,
    output_capacity: int | None = None,
    output_is_null: bool = False,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> tuple[int, bytes]:
    if type(output_is_null) is not bool or type(input_is_null) is not bool:
        return INVALID, b""
    parsed = _parse(values, input_is_null, input_length)
    if parsed is None:
        return INVALID, b""
    if output_capacity is not None and (
        type(output_capacity) is not int or output_capacity < 0
    ):
        return INVALID, b""
    _, b_points, queries = parsed
    required = 8 * len(queries)
    if output_is_null or (output_capacity is not None and output_capacity < required):
        return OUTPUT_ERROR, b""
    answers = _evaluate(*parsed)
    return required, b"".join(struct.pack("<q", count) for count in answers)
