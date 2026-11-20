"""Cubic supporting-edge oracle, independent of the bridge recursion."""

from __future__ import annotations

from collections.abc import Sequence

MIN_POINTS = 3
MAX_POINTS = 32
MAX_PARSEABLE_INPUT_LENGTH = 66
MAX_COORDINATE = 1000
INVALID_RESULT = -1
OUTPUT_ERROR = -2
_I64_MIN = -(1 << 63)
_I64_MAX = (1 << 63) - 1


def _parse(values: Sequence[int] | None, input_is_null: bool,
           input_length: int | None) -> list[tuple[int, int]] | None:
    if (input_is_null or not isinstance(values, (list, tuple))
            or not 1 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
            or any(type(value) is not int or value < _I64_MIN or value > _I64_MAX
                   for value in values)):
        return None
    if input_length is not None and input_length != len(values):
        return None
    n = values[0]
    if not MIN_POINTS <= n <= MAX_POINTS or len(values) != 1 + 2 * n:
        return None
    points = [(values[i], values[i + 1]) for i in range(1, len(values), 2)]
    if any(not -MAX_COORDINATE <= x <= MAX_COORDINATE
           or not -MAX_COORDINATE <= y <= MAX_COORDINATE for x, y in points):
        return None
    if len({x for x, _ in points}) != n:
        return None
    first, second = points[0], points[1]
    if all((second[0] - first[0]) * (point[1] - first[1])
           == (second[1] - first[1]) * (point[0] - first[0])
           for point in points[2:]):
        return None
    return points


def _strict_hull(points: list[tuple[int, int]]) -> list[tuple[int, int]]:
    directed_edges: set[tuple[int, int]] = set()
    for first in range(len(points)):
        for second in range(first + 1, len(points)):
            a, b = points[first], points[second]
            low, high = (first, second) if a[0] < b[0] else (second, first)
            left_point, right_point = points[low], points[high]
            signs = [
                (right_point[0] - left_point[0]) * (point[1] - left_point[1])
                - (right_point[1] - left_point[1]) * (point[0] - left_point[0])
                for point in points
            ]
            if all(value >= 0 for value in signs):
                side = 1
            elif all(value <= 0 for value in signs):
                side = -1
            else:
                continue
            contacts = [index for index, value in enumerate(signs) if value == 0]
            edge_left = min(contacts, key=lambda index: points[index][0])
            edge_right = max(contacts, key=lambda index: points[index][0])
            directed_edges.add((edge_left, edge_right) if side > 0
                                else (edge_right, edge_left))

    outgoing: dict[int, int] = {}
    for start, end in directed_edges:
        outgoing[start] = end
    first = min(range(len(points)), key=lambda index: points[index][0])
    cycle: list[int] = []
    current = first
    while current not in cycle:
        cycle.append(current)
        current = outgoing[current]
    return [points[index] for index in cycle]


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or capacity is not None and (type(capacity) is not int or capacity < 0)
            or input_length is not None and (
                type(input_length) is not int
                or not 0 <= input_length <= MAX_PARSEABLE_INPUT_LENGTH)
            or input_is_null and values not in (None, [], ())
            or not input_is_null and values is not None and input_length is not None
            and (not isinstance(values, (list, tuple)) or input_length != len(values))):
        return INVALID_RESULT, b""
    if input_is_null or values is None:
        return INVALID_RESULT, b""
    points = _parse(values, input_is_null, input_length)
    if points is None:
        return INVALID_RESULT, b""
    hull = _strict_hull(points)
    packed = b"".join(value.to_bytes(8, "little", signed=True)
                      for point in hull for value in point)
    if output_is_null or capacity is not None and capacity < len(packed):
        return OUTPUT_ERROR, b""
    return len(packed), packed
