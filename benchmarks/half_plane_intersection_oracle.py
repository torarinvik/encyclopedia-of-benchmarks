"""Primary exact deque oracle for a bounded half-plane intersection profile."""

from __future__ import annotations

import math
import struct
from collections.abc import Sequence
from functools import cmp_to_key
from fractions import Fraction

MAX_CONSTRAINTS = 12
MAX_INPUT_LENGTH = 37
MAX_OUTPUT_VERTICES = 16
MAX_OUTPUT_BYTES = 520
WORKSPACE_BYTES = 8192
BOX = 256
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1

Line = tuple[int, int, int]
Point = tuple[int, int, int]  # common-denominator x, y, denominator


def _half(a: int, b: int) -> int:
    return 0 if b > 0 or (b == 0 and a >= 0) else 1


def _line_compare(first: Line, second: Line) -> int:
    ha, hb = _half(first[0], first[1]), _half(second[0], second[1])
    if ha != hb:
        return -1 if ha < hb else 1
    turn = first[0] * second[1] - first[1] * second[0]
    if turn:
        return -1 if turn > 0 else 1
    # Primitive normals with equal angle are identical; retain the tightest.
    return (first[2] > second[2]) - (first[2] < second[2])


def _intersection(first: Line, second: Line) -> Point | None:
    a, b, c = first
    d, e, f = second
    det = a * e - d * b
    if det == 0:
        return None
    x = c * e - b * f
    y = a * f - c * d
    if det < 0:
        det, x, y = -det, -x, -y
    common = math.gcd(math.gcd(abs(x), abs(y)), det)
    return x // common, y // common, det // common


def _outside(line: Line, point: Point) -> bool:
    a, b, c = line
    x, y, den = point
    return a * x + b * y > c * den


def _same_point(first: Point, second: Point) -> bool:
    return (first[0] * second[2] == second[0] * first[2]
            and first[1] * second[2] == second[1] * first[2])


def _orient(a: Point, b: Point, c: Point) -> int:
    dx1 = b[0] * a[2] - a[0] * b[2]
    dy1 = b[1] * a[2] - a[1] * b[2]
    dx2 = c[0] * b[2] - b[0] * c[2]
    dy2 = c[1] * b[2] - b[1] * c[2]
    return dx1 * dy2 - dy1 * dx2


def _clean_cycle(points: Sequence[Point]) -> list[Point]:
    unique: list[Point] = []
    for point in points:
        if not unique or not _same_point(unique[-1], point):
            unique.append(point)
    if len(unique) > 1 and _same_point(unique[0], unique[-1]):
        unique.pop()
    changed = True
    while changed and len(unique) >= 3:
        changed = False
        for index in range(len(unique)):
            if _orient(unique[index - 1], unique[index], unique[(index + 1) % len(unique)]) == 0:
                unique.pop(index)
                changed = True
                break
    if len(unique) < 3:
        return []
    first = min(range(len(unique)), key=lambda i: (Fraction(unique[i][1], unique[i][2]),
                                                    Fraction(unique[i][0], unique[i][2])))
    return unique[first:] + unique[:first]


def _parse(values: Sequence[int] | None, input_length: int | None,
           input_is_null: bool) -> list[Line] | None:
    if type(input_is_null) is not bool or input_is_null or not isinstance(values, (list, tuple)):
        return None
    if not 1 <= len(values) <= MAX_INPUT_LENGTH:
        return None
    if input_length is not None and (type(input_length) is not int or input_length != len(values)):
        return None
    if any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values):
        return None
    count = values[0]
    if not 0 <= count <= MAX_CONSTRAINTS or len(values) != 1 + 3 * count:
        return None
    lines: list[Line] = []
    for index in range(count):
        a, b, c = values[1 + 3 * index:4 + 3 * index]
        if not (-16 <= a <= 16 and -16 <= b <= 16 and -128 <= c <= 128):
            return None
        if (a == 0 and b == 0) or math.gcd(abs(a), abs(b)) != 1:
            return None
        lines.append((a, b, c))
    return lines


def _deque_vertices(constraints: Sequence[Line]) -> list[Point]:
    lines = list(constraints) + [(1, 0, BOX), (0, 1, BOX),
                                  (-1, 0, BOX), (0, -1, BOX)]
    lines.sort(key=cmp_to_key(_line_compare))
    reduced: list[Line] = []
    for line in lines:
        if reduced and line[:2] == reduced[-1][:2]:
            continue  # c order is ascending, so the first line is tightest.
        reduced.append(line)

    queue: list[Line] = []
    for line in reduced:
        while len(queue) > 1:
            point = _intersection(queue[-2], queue[-1])
            if point is None or not _outside(line, point):
                break
            queue.pop()
        while len(queue) > 1:
            point = _intersection(queue[0], queue[1])
            if point is None or not _outside(line, point):
                break
            queue.pop(0)
        if queue:
            last = queue[-1]
            turn = last[0] * line[1] - last[1] * line[0]
            if turn == 0:
                dot = last[0] * line[0] + last[1] * line[1]
                if dot < 0:
                    return []
                if line[2] < last[2]:
                    queue[-1] = line
                continue
        queue.append(line)

    while len(queue) > 2:
        point = _intersection(queue[-2], queue[-1])
        if point is None or not _outside(queue[0], point):
            break
        queue.pop()
    while len(queue) > 2:
        point = _intersection(queue[0], queue[1])
        if point is None or not _outside(queue[-1], point):
            break
        queue.pop(0)
    if len(queue) < 3:
        return []
    vertices: list[Point] = []
    for index, line in enumerate(queue):
        point = _intersection(line, queue[(index + 1) % len(queue)])
        if point is None:
            return []
        vertices.append(point)
    return _clean_cycle(vertices)


def _encode(points: Sequence[Point]) -> bytes:
    words = [len(points)]
    for x, y, den in points:
        gx = math.gcd(abs(x), den)
        gy = math.gcd(abs(y), den)
        words.extend((x // gx, den // gx, y // gy, den // gy))
    return b"".join(struct.pack("<q", word) for word in words)


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    constraints = _parse(values, input_length, input_is_null)
    if constraints is None:
        return -1, b""
    encoded = _encode(_deque_vertices(constraints))
    effective_capacity = MAX_OUTPUT_BYTES if capacity is None else capacity
    if (type(output_is_null) is not bool or type(effective_capacity) is not int
            or effective_capacity < 0):
        return -2, b""
    if output_is_null or len(encoded) > effective_capacity:
        return -2, b""
    return len(encoded), encoded
