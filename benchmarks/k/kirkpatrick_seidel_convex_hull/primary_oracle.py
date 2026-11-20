"""Clean-room bounded Kirkpatrick–Seidel convex-hull reference."""

from __future__ import annotations

from collections.abc import Sequence
from typing import TypeVar

Point = tuple[int, int]
Slope = tuple[int, int]  # (dy, dx), with dx > 0
T = TypeVar("T")

MIN_POINTS = 3
MAX_POINTS = 32
MAX_VALID_INPUT_LENGTH = 65
MAX_PARSEABLE_INPUT_LENGTH = 66
MAX_OUTPUT_BYTES = 512
MAX_COORDINATE = 1000
INVALID_RESULT = -1
OUTPUT_ERROR = -2
_I64_MIN = -(1 << 63)
_I64_MAX = (1 << 63) - 1


def _compare_slope(first: Slope, second: Slope) -> int:
    left = first[0] * second[1]
    right = second[0] * first[1]
    return (left > right) - (left < right)


def _small_sort(items: list[T], less) -> None:
    for index in range(1, len(items)):
        item = items[index]
        cursor = index
        while cursor and less(item, items[cursor - 1]):
            items[cursor] = items[cursor - 1]
            cursor -= 1
        items[cursor] = item


def _select(items: list[T], rank: int, less) -> T:
    """Deterministic median-of-medians selection with three-way partitioning."""
    if len(items) <= 5:
        _small_sort(items, less)
        return items[rank]
    medians: list[T] = []
    for start in range(0, len(items), 5):
        group = items[start:start + 5]
        _small_sort(group, less)
        medians.append(group[(len(group) - 1) // 2])
    pivot = _select(medians, (len(medians) - 1) // 2, less)
    lower: list[T] = []
    equal: list[T] = []
    upper: list[T] = []
    for item in items:
        if less(item, pivot):
            lower.append(item)
        elif less(pivot, item):
            upper.append(item)
        else:
            equal.append(item)
    if rank < len(lower):
        return _select(lower, rank, less)
    if rank < len(lower) + len(equal):
        return pivot
    return _select(upper, rank - len(lower) - len(equal), less)


def _slope(first: Point, second: Point) -> Slope:
    if first[0] > second[0]:
        first, second = second, first
    return second[1] - first[1], second[0] - first[0]


def _upper_bridge(points: Sequence[Point], candidates: list[int], separator: int) -> tuple[int, int]:
    while len(candidates) > 2:
        pair_slopes = [
            _slope(points[candidates[i]], points[candidates[i + 1]])
            for i in range(0, len(candidates) - 1, 2)
        ]
        median = _select(pair_slopes, (len(pair_slopes) - 1) // 2,
                         lambda first, second: _compare_slope(first, second) < 0)
        support = max(points[index][1] * median[1] - median[0] * points[index][0]
                      for index in candidates)
        contacts = [index for index in candidates
                    if points[index][1] * median[1] - median[0] * points[index][0] == support]
        left = min(contacts, key=lambda index: points[index][0])
        right = max(contacts, key=lambda index: points[index][0])
        if points[left][0] <= separator < points[right][0]:
            return left, right

        support_is_left = points[right][0] <= separator
        retained: list[int] = []
        for offset in range(0, len(candidates) - 1, 2):
            first, second = candidates[offset], candidates[offset + 1]
            order = _compare_slope(_slope(points[first], points[second]), median)
            if support_is_left:
                if order < 0:
                    retained.extend((first, second))
                else:
                    retained.append(max((first, second), key=lambda index: points[index][0]))
            elif order > 0:
                retained.extend((first, second))
            else:
                retained.append(min((first, second), key=lambda index: points[index][0]))
        if len(candidates) % 2:
            retained.append(candidates[-1])
        candidates = retained
    return tuple(sorted(candidates, key=lambda index: points[index][0]))  # type: ignore[return-value]


def _connect_upper(points: Sequence[Point], candidates: list[int], left: int,
                   right: int, chain: list[int]) -> None:
    if left == right:
        if not chain or chain[-1] != left:
            chain.append(left)
        return
    median_rank = (len(candidates) - 1) // 2
    separator = points[_select(candidates.copy(), median_rank,
                               lambda a, b: points[a][0] < points[b][0])][0]
    bridge_left, bridge_right = _upper_bridge(points, candidates.copy(), separator)
    left_set = [index for index in candidates if points[index][0] <= points[bridge_left][0]]
    right_set = [index for index in candidates if points[index][0] >= points[bridge_right][0]]
    _connect_upper(points, left_set, left, bridge_left, chain)
    if not chain or chain[-1] != bridge_right:
        chain.append(bridge_right)
    _connect_upper(points, right_set, bridge_right, right, chain)


def _decode(values: Sequence[int] | None, input_is_null: bool,
            input_length: int | None) -> list[Point] | None:
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple))
            or not 1 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
            or any(type(value) is not int or not _I64_MIN <= value <= _I64_MAX
                   for value in values)):
        return None
    if input_length is not None and (
            type(input_length) is not int or input_length != len(values)):
        return None
    count = values[0]
    if not MIN_POINTS <= count <= MAX_POINTS or len(values) != 1 + 2 * count:
        return None
    points: list[Point] = []
    seen_x: set[int] = set()
    for offset in range(1, len(values), 2):
        x, y = values[offset], values[offset + 1]
        if (not -MAX_COORDINATE <= x <= MAX_COORDINATE
                or not -MAX_COORDINATE <= y <= MAX_COORDINATE or x in seen_x):
            return None
        seen_x.add(x)
        points.append((x, y))
    if all((points[1][0] - points[0][0]) * (point[1] - points[0][1])
           == (points[1][1] - points[0][1]) * (point[0] - points[0][0])
           for point in points[2:]):
        return None
    return points


def _hull(points: list[Point]) -> list[Point]:
    ids = list(range(len(points)))
    left = min(ids, key=lambda index: points[index][0])
    right = max(ids, key=lambda index: points[index][0])
    upper_points = points
    lower_points = [(x, -y) for x, y in points]
    upper: list[int] = []
    lower: list[int] = []
    _connect_upper(upper_points, ids.copy(), left, right, upper)
    _connect_upper(lower_points, ids.copy(), left, right, lower)
    return ([points[index] for index in lower]
            + [points[upper[index]] for index in range(len(upper) - 2, 0, -1)])


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or capacity is not None and (type(capacity) is not int or capacity < 0)
            or input_length is not None and (
                type(input_length) is not int or not 0 <= input_length <= MAX_PARSEABLE_INPUT_LENGTH)
            or input_is_null and values not in (None, [], ())
            or not input_is_null and values is not None and input_length is not None
            and (not isinstance(values, (list, tuple)) or input_length != len(values))):
        return INVALID_RESULT, b""
    if input_is_null or values is None:
        return INVALID_RESULT, b""
    points = _decode(values, input_is_null, input_length)
    if points is None:
        return INVALID_RESULT, b""
    hull = _hull(points)
    staged = b"".join(component.to_bytes(8, "little", signed=True)
                      for point in hull for component in point)
    if output_is_null or capacity is not None and capacity < len(staged):
        return OUTPUT_ERROR, b""
    return len(staged), staged
