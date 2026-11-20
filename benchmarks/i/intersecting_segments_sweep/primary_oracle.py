"""Endpoint sweep with an array-backed ordered active set."""

from __future__ import annotations

from collections.abc import Sequence

MAX_SEGMENTS = 24
MAX_PARSEABLE_LENGTH = 98
COORD_MIN = -100
COORD_MAX = 100
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1

Segment = tuple[int, int, int, int]


def _parse(values: Sequence[int]) -> list[Segment] | None:
    if (not isinstance(values, Sequence) or len(values) < 1
            or len(values) > MAX_PARSEABLE_LENGTH
            or any(type(value) is not int or value < I64_MIN or value > I64_MAX
                   for value in values)):
        return None
    count = values[0]
    if not 0 <= count <= MAX_SEGMENTS or len(values) != 1 + 4 * count:
        return None
    used_x: set[int] = set()
    segments: list[Segment] = []
    for offset in range(1, len(values), 4):
        x1, y1, x2, y2 = values[offset:offset + 4]
        if (not COORD_MIN <= x1 <= COORD_MAX or not COORD_MIN <= x2 <= COORD_MAX
                or not COORD_MIN <= y1 <= COORD_MAX or not COORD_MIN <= y2 <= COORD_MAX
                or x1 >= x2 or x1 in used_x or x2 in used_x):
            return None
        used_x.add(x1)
        used_x.add(x2)
        segments.append((x1, y1, x2, y2))
    return segments


def _orientation(a: tuple[int, int], b: tuple[int, int], c: tuple[int, int]) -> int:
    cross = (b[0] - a[0]) * (c[1] - a[1]) - (b[1] - a[1]) * (c[0] - a[0])
    return (cross > 0) - (cross < 0)


def _intersects(first: Segment, second: Segment) -> bool:
    ax1, ay1, ax2, ay2 = first
    bx1, by1, bx2, by2 = second
    if (max(ax1, bx1) > min(ax2, bx2) or max(min(ay1, ay2), min(by1, by2))
            > min(max(ay1, ay2), max(by1, by2))):
        return False
    a, b = (ax1, ay1), (ax2, ay2)
    c, d = (bx1, by1), (bx2, by2)
    return (_orientation(a, b, c) * _orientation(a, b, d) <= 0
            and _orientation(c, d, a) * _orientation(c, d, b) <= 0)


def _compare_at_x(first: Segment, first_id: int, second: Segment,
                  second_id: int, x: int) -> int:
    ax1, ay1, ax2, ay2 = first
    bx1, by1, bx2, by2 = second
    adx, bdx = ax2 - ax1, bx2 - bx1
    anum = ay1 * adx + (ay2 - ay1) * (x - ax1)
    bnum = by1 * bdx + (by2 - by1) * (x - bx1)
    left, right = anum * bdx, bnum * adx
    if left != right:
        return -1 if left < right else 1
    aslope, bslope = (ay2 - ay1) * bdx, (by2 - by1) * adx
    if aslope != bslope:
        return -1 if aslope < bslope else 1
    return (first_id > second_id) - (first_id < second_id)


def has_intersection(values: Sequence[int]) -> bool | None:
    """Return whether the valid input contains an intersecting pair."""
    segments = _parse(values)
    if segments is None:
        return None
    events = sorted((x, is_start, segment_id)
                    for segment_id, (x1, _, x2, _) in enumerate(segments)
                    for x, is_start in ((x1, True), (x2, False)))
    active: list[int] = []
    for x, is_start, segment_id in events:
        if is_start:
            position = 0
            while (position < len(active)
                   and _compare_at_x(segments[active[position]], active[position],
                                     segments[segment_id], segment_id, x) < 0):
                position += 1
            if position > 0 and _intersects(segments[active[position - 1]], segments[segment_id]):
                return True
            if position < len(active) and _intersects(segments[active[position]], segments[segment_id]):
                return True
            active.insert(position, segment_id)
        else:
            position = active.index(segment_id)
            if (position > 0 and position + 1 < len(active)
                    and _intersects(segments[active[position - 1]], segments[active[position + 1]])):
                return True
            active.pop(position)
    return False


def expected_result(values: Sequence[int], *, input_length: int | None = None,
                    input_is_null: bool = False) -> int:
    if (type(input_is_null) is not bool
            or (input_length is not None and type(input_length) is not int)
            or (input_length is not None and input_length < 0)):
        return -1
    if input_is_null or not isinstance(values, Sequence):
        return -1
    if any(type(value) is not int or value < I64_MIN or value > I64_MAX for value in values):
        return -1
    if input_length is not None and input_length != len(values):
        return -1
    result = has_intersection(values)
    if result is None:
        return -1
    return int(result)
