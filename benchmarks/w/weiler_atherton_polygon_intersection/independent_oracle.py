"""Boundary-fragment arrangement reference for polygon intersection."""

from __future__ import annotations

from collections.abc import Sequence
from fractions import Fraction

MAX_VERTICES = 6
COORDINATE_LIMIT = 16
MAX_PARSEABLE_INPUT_LENGTH = 27
MAX_OUTPUT_BYTES = 1680
WORKSPACE_BYTES = 65536
INVALID_RESULT = -1
OUTPUT_ERROR = -2
_I64_MIN = -(1 << 63)
_I64_MAX = (1 << 63) - 1

IPoint = tuple[int, int]
Point = tuple[Fraction, Fraction]


def _cross(x1: int | Fraction, y1: int | Fraction,
           x2: int | Fraction, y2: int | Fraction) -> int | Fraction:
    return x1 * y2 - y1 * x2


def _turn(a: IPoint, b: IPoint, c: IPoint) -> int:
    return _cross(b[0] - a[0], b[1] - a[1],
                  c[0] - a[0], c[1] - a[1])


def _between(a: IPoint, b: IPoint, c: IPoint) -> bool:
    return (_turn(a, b, c) == 0
            and min(a[0], b[0]) <= c[0] <= max(a[0], b[0])
            and min(a[1], b[1]) <= c[1] <= max(a[1], b[1]))


def _relation(a: IPoint, b: IPoint, c: IPoint, d: IPoint) -> str:
    p, q = _turn(a, b, c), _turn(a, b, d)
    r, s = _turn(c, d, a), _turn(c, d, b)
    if (p > 0 > q or q > 0 > p) and (r > 0 > s or s > 0 > r):
        return "proper"
    if ((_between(a, b, c) if p == 0 else False)
            or (_between(a, b, d) if q == 0 else False)
            or (_between(c, d, a) if r == 0 else False)
            or (_between(c, d, b) if s == 0 else False)):
        return "touch"
    return "none"


def _valid(poly: list[IPoint]) -> bool:
    size = len(poly)
    if len(set(poly)) != size:
        return False
    area2 = sum(poly[i][0] * poly[(i + 1) % size][1]
                - poly[i][1] * poly[(i + 1) % size][0] for i in range(size))
    if area2 <= 0:
        return False
    for i in range(size):
        if _turn(poly[i - 1], poly[i], poly[(i + 1) % size]) == 0:
            return False
        for j in range(i + 1, size):
            if j == i + 1 or (i == 0 and j == size - 1):
                continue
            if _relation(poly[i], poly[(i + 1) % size],
                         poly[j], poly[(j + 1) % size]) != "none":
                return False
    return True


def _decode(values: Sequence[int] | None, null_input: bool,
            length: int | None) -> tuple[list[IPoint], list[IPoint]] | None:
    if (type(null_input) is not bool or null_input
            or not isinstance(values, (tuple, list))
            or not 2 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
            or any(type(v) is not int or not _I64_MIN <= v <= _I64_MAX for v in values)):
        return None
    if length is not None and (type(length) is not int or length != len(values)):
        return None
    na, nb = values[0], values[1]
    if not 3 <= na <= MAX_VERTICES or not 3 <= nb <= MAX_VERTICES:
        return None
    if len(values) != 2 + 2 * na + 2 * nb:
        return None
    coords = values[2:]
    if any(not -COORDINATE_LIMIT <= v <= COORDINATE_LIMIT for v in coords):
        return None
    cut = 2 * na
    a = [(coords[k], coords[k + 1]) for k in range(0, cut, 2)]
    b = [(coords[k], coords[k + 1]) for k in range(cut, len(coords), 2)]
    if not _valid(a) or not _valid(b):
        return None
    return a, b


def _point(edge_a: IPoint, edge_b: IPoint, t: Fraction) -> Point:
    return (Fraction(edge_a[0]) + t * (edge_b[0] - edge_a[0]),
            Fraction(edge_a[1]) + t * (edge_b[1] - edge_a[1]))


def _crossing_parameter(a: IPoint, b: IPoint,
                        c: IPoint, d: IPoint) -> Fraction:
    rx, ry = b[0] - a[0], b[1] - a[1]
    sx, sy = d[0] - c[0], d[1] - c[1]
    return Fraction(_cross(c[0] - a[0], c[1] - a[1], sx, sy),
                    _cross(rx, ry, sx, sy))


def _inside(point: Point, poly: list[IPoint]) -> bool:
    x, y = point
    winding = 0
    for k, a in enumerate(poly):
        b = poly[(k + 1) % len(poly)]
        side = _cross(b[0] - a[0], b[1] - a[1], x - a[0], y - a[1])
        if a[1] <= y < b[1] and side > 0:
            winding += 1
        elif b[1] <= y < a[1] and side < 0:
            winding -= 1
    return winding != 0


def _arrangement(a: list[IPoint], b: list[IPoint]) -> list[list[Point]] | None:
    pieces: list[tuple[Point, Point]] = []
    for source, other in ((a, b), (b, a)):
        for edge, start in enumerate(source):
            end = source[(edge + 1) % len(source)]
            parameters = [Fraction(0), Fraction(1)]
            for other_edge, q in enumerate(other):
                q2 = other[(other_edge + 1) % len(other)]
                relation = _relation(start, end, q, q2)
                if relation == "touch":
                    return None
                if relation == "proper":
                    parameters.append(_crossing_parameter(start, end, q, q2))
            parameters = sorted(set(parameters))
            for left, right in zip(parameters, parameters[1:]):
                p0, p1 = _point(start, end, left), _point(start, end, right)
                midpoint = ((p0[0] + p1[0]) / 2, (p0[1] + p1[1]) / 2)
                if _inside(midpoint, other):
                    pieces.append((p0, p1))

    outgoing: dict[Point, int] = {}
    for index, (start, _) in enumerate(pieces):
        if start in outgoing:
            return None
        outgoing[start] = index
    unused = set(range(len(pieces)))
    rings: list[list[Point]] = []
    while unused:
        first = min(unused, key=lambda i: (pieces[i][0], pieces[i][1]))
        start = pieces[first][0]
        ring = [start]
        current = first
        guard = 0
        while True:
            guard += 1
            if current not in unused or guard > len(pieces) + 1:
                return None
            unused.remove(current)
            end = pieces[current][1]
            if end == start:
                break
            ring.append(end)
            current = outgoing.get(end, -1)
            if current < 0:
                return None
        rings.append(ring)
    return rings


def _canonical(rings: list[list[Point]]) -> list[list[Point]]:
    normalized: list[list[Point]] = []
    for ring in rings:
        compact = [p for i, p in enumerate(ring) if i == 0 or p != ring[i - 1]]
        if len(compact) > 1 and compact[0] == compact[-1]:
            compact.pop()
        if len(compact) >= 3:
            pivot = min(range(len(compact)), key=lambda i: compact[i])
            normalized.append(compact[pivot:] + compact[:pivot])
    normalized.sort(key=lambda ring: tuple(ring))
    return normalized


def _serialize(rings: list[list[Point]]) -> bytes:
    rings = _canonical(rings)
    words = [len(rings)]
    for ring in rings:
        words.append(len(ring))
        for x, y in ring:
            words.extend((x.numerator, x.denominator, y.numerator, y.denominator))
    return b"".join(value.to_bytes(8, "little", signed=True) for value in words)


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or capacity is not None and (type(capacity) is not int or capacity < 0)
            or input_length is not None and (type(input_length) is not int
                                              or not 0 <= input_length <= MAX_PARSEABLE_INPUT_LENGTH)
            or input_is_null and values not in (None, [], ())
            or not input_is_null and values is not None and input_length is not None
            and (not isinstance(values, (tuple, list)) or input_length != len(values))):
        return INVALID_RESULT, b""
    if input_is_null or values is None:
        return INVALID_RESULT, b""
    decoded = _decode(values, input_is_null, input_length)
    if decoded is None:
        return INVALID_RESULT, b""
    rings = _arrangement(*decoded)
    if rings is None:
        return INVALID_RESULT, b""
    staged = _serialize(rings)
    if len(staged) > MAX_OUTPUT_BYTES:
        return INVALID_RESULT, b""
    if output_is_null or capacity is not None and capacity < len(staged):
        return OUTPUT_ERROR, b""
    return len(staged), staged
