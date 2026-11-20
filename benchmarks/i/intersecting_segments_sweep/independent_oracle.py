"""All-pairs segment test, independent of the endpoint-sweep reference."""

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
    if (not isinstance(values, Sequence) or not 1 <= len(values) <= MAX_PARSEABLE_LENGTH
            or any(type(value) is not int or value < I64_MIN or value > I64_MAX
                   for value in values)):
        return None
    count = values[0]
    if not 0 <= count <= MAX_SEGMENTS or len(values) != 1 + 4 * count:
        return None
    points: set[int] = set()
    segments: list[Segment] = []
    for offset in range(1, len(values), 4):
        x1, y1, x2, y2 = values[offset:offset + 4]
        if (not COORD_MIN <= x1 <= COORD_MAX or not COORD_MIN <= x2 <= COORD_MAX
                or not COORD_MIN <= y1 <= COORD_MAX or not COORD_MIN <= y2 <= COORD_MAX
                or x1 >= x2 or x1 in points or x2 in points):
            return None
        points.update((x1, x2))
        segments.append((x1, y1, x2, y2))
    return segments


def _cross(a: tuple[int, int], b: tuple[int, int], c: tuple[int, int]) -> int:
    return (b[0] - a[0]) * (c[1] - a[1]) - (b[1] - a[1]) * (c[0] - a[0])


def _on_segment(a: tuple[int, int], b: tuple[int, int], p: tuple[int, int]) -> bool:
    return (min(a[0], b[0]) <= p[0] <= max(a[0], b[0])
            and min(a[1], b[1]) <= p[1] <= max(a[1], b[1]))


def _pair_intersects(one: Segment, two: Segment) -> bool:
    a = (one[0], one[1])
    b = (one[2], one[3])
    c = (two[0], two[1])
    d = (two[2], two[3])
    ab_c, ab_d = _cross(a, b, c), _cross(a, b, d)
    cd_a, cd_b = _cross(c, d, a), _cross(c, d, b)
    if ab_c == 0 and _on_segment(a, b, c): return True
    if ab_d == 0 and _on_segment(a, b, d): return True
    if cd_a == 0 and _on_segment(c, d, a): return True
    if cd_b == 0 and _on_segment(c, d, b): return True
    return ((ab_c < 0 < ab_d or ab_d < 0 < ab_c)
            and (cd_a < 0 < cd_b or cd_b < 0 < cd_a))


def has_intersection(values: Sequence[int]) -> bool | None:
    segments = _parse(values)
    if segments is None:
        return None
    for first in range(len(segments)):
        for second in range(first + 1, len(segments)):
            if _pair_intersects(segments[first], segments[second]):
                return True
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
