"""Binary-search reference for directed-line/convex-polygon intersections."""

from __future__ import annotations

import struct

MIN_VERTICES = 3
MAX_VERTICES = 16
MAX_COORDINATE = 50
MAX_VALID_INPUT_LENGTH = 5 + 2 * MAX_VERTICES
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_OUTPUT_BYTES = 16


def _half(vector):
    x, y = vector
    return 0 if y > 0 or (y == 0 and x >= 0) else 1


def _angle_before(left, right):
    lh, rh = _half(left), _half(right)
    if lh != rh:
        return lh < rh
    return left[0] * right[1] - left[1] * right[0] > 0


def _parse(values, input_length=None, input_is_null=False):
    if input_is_null or not isinstance(values, (list, tuple)):
        return None
    if input_length is None:
        input_length = len(values)
    if (type(input_length) is not int or input_length < 1
            or input_length > MAX_PARSEABLE_INPUT_LENGTH
            or input_length != len(values)):
        return None
    if any(type(v) is not int or not -(1 << 63) <= v < (1 << 63) for v in values):
        return None
    n = values[0]
    if type(n) is not int or not MIN_VERTICES <= n <= MAX_VERTICES:
        return None
    if input_length != 5 + 2 * n:
        return None
    x1, y1, x2, y2 = values[1:5]
    if any(abs(value) > MAX_COORDINATE for value in (x1, y1, x2, y2)):
        return None
    dx, dy = x2 - x1, y2 - y1
    if dx == 0 and dy == 0:
        return None
    points = []
    for i in range(n):
        x, y = values[5 + 2 * i:7 + 2 * i]
        if abs(x) > MAX_COORDINATE or abs(y) > MAX_COORDINATE:
            return None
        points.append((x, y))
    if len(set(points)) != n:
        return None
    area2 = sum(points[i][0] * points[(i + 1) % n][1]
                - points[(i + 1) % n][0] * points[i][1] for i in range(n))
    if area2 <= 0:
        return None
    for i, (x0, y0) in enumerate(points):
        x1e, y1e = points[(i + 1) % n]
        for j, (x, y) in enumerate(points):
            if j == i or j == (i + 1) % n:
                continue
            if (x1e - x0) * (y - y0) - (y1e - y0) * (x - x0) <= 0:
                return None
    edges = [(points[(i + 1) % n][0] - points[i][0],
              points[(i + 1) % n][1] - points[i][1]) for i in range(n)]
    return points, edges, (x1, y1), (dx, dy)


def _rotation_minimum(edges):
    low, high = 0, len(edges) - 1
    while low < high:
        middle = (low + high) // 2
        if _angle_before(edges[middle], edges[high]):
            high = middle
        else:
            low = middle + 1
    return low


def _support_edge(edges, target):
    pivot = _rotation_minimum(edges)
    count = len(edges)
    low, high = 0, count
    while low < high:
        middle = (low + high) // 2
        if _angle_before(edges[(pivot + middle) % count], target):
            low = middle + 1
        else:
            high = middle
    return (pivot + low) % count


def _line_value(point, origin, direction):
    return (direction[0] * (point[1] - origin[1])
            - direction[1] * (point[0] - origin[0]))


def _line_parameter_for_vertex(point, origin, direction):
    return ((point[0] - origin[0]) * direction[0]
            + (point[1] - origin[1]) * direction[1])


def _crossing(points, origin, direction, start, end, increasing):
    n = len(points)
    span = (end - start) % n
    low, high = 0, span

    def value(offset):
        return _line_value(points[(start + offset) % n], origin, direction)

    if increasing:
        while high - low > 1:
            middle = (low + high) // 2
            if value(middle) < 0:
                low = middle
            else:
                high = middle
        index = (start + high) % n if value(high) == 0 else (start + low) % n
    else:
        while high - low > 1:
            middle = (low + high) // 2
            if value(middle) > 0:
                low = middle
            else:
                high = middle
        index = (start + high) % n if value(high) == 0 else (start + low) % n

    current = points[index]
    current_value = _line_value(current, origin, direction)
    if current_value == 0:
        return index, _line_parameter_for_vertex(current, origin, direction), 1
    following = points[(index + 1) % n]
    following_value = _line_value(following, origin, direction)
    denominator = current_value - following_value
    edge_dx, edge_dy = following[0] - current[0], following[1] - current[1]
    numerator = (
        _line_parameter_for_vertex(current, origin, direction) * denominator
        + current_value * (edge_dx * direction[0] + edge_dy * direction[1])
    )
    if denominator < 0:
        numerator, denominator = -numerator, -denominator
    return index, numerator, denominator


def expected_output(values, capacity=None, input_is_null=False,
                    output_is_null=False, input_length=None):
    parsed = _parse(values, input_length, input_is_null)
    if parsed is None:
        return -1, b""
    points, edges, origin, direction = parsed
    dx, dy = direction
    n = len(points)
    # The maximum of cross(direction, p-origin) has normal (-dy, dx).
    maximum = _support_edge(edges, (-dx, -dy))
    minimum = _support_edge(edges, (dx, dy))
    max_value = _line_value(points[maximum], origin, direction)
    min_value = _line_value(points[minimum], origin, direction)
    if min_value > 0 or max_value < 0:
        result = (-1, -1)
    elif min_value == 0 or max_value == 0:
        touch = minimum if min_value == 0 else maximum
        following = (touch + 1) % n
        previous = (touch - 1) % n
        if (_line_value(points[touch], origin, direction) == 0
                and _line_value(points[following], origin, direction) == 0):
            result = (touch, touch)
        elif (_line_value(points[previous], origin, direction) == 0
              and _line_value(points[touch], origin, direction) == 0):
            result = (previous, previous)
        else:
            result = (touch, -1)
    else:
        first = _crossing(points, origin, direction, maximum, minimum, False)
        second = _crossing(points, origin, direction, minimum, maximum, True)
        numerator_a, denominator_a = first[1], first[2]
        numerator_b, denominator_b = second[1], second[2]
        if numerator_a * denominator_b <= numerator_b * denominator_a:
            result = (first[0], second[0])
        else:
            result = (second[0], first[0])

    effective_capacity = MAX_OUTPUT_BYTES if capacity is None else capacity
    if (type(output_is_null) is not bool or type(effective_capacity) is not int
            or effective_capacity < 0):
        return -2, b""
    if output_is_null or effective_capacity < MAX_OUTPUT_BYTES:
        return -2, b""
    output = struct.pack("<qq", *result)
    return len(output), output


def expected_result(values, **kwargs):
    return expected_output(values, **kwargs)[0]
