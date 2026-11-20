"""Exact bounded Weiler–Atherton intersection of two simple polygons."""

from __future__ import annotations

from collections.abc import Sequence
from fractions import Fraction

MIN_VERTICES = 3
MAX_VERTICES = 6
COORDINATE_LIMIT = 16
MAX_VALID_INPUT_LENGTH = 26
MAX_PARSEABLE_INPUT_LENGTH = 27
MAX_OUTPUT_BYTES = 1680
WORKSPACE_BYTES = 65536
INVALID_RESULT = -1
OUTPUT_ERROR = -2
_I64_MIN = -(1 << 63)
_I64_MAX = (1 << 63) - 1

Point = tuple[Fraction, Fraction]
IntPoint = tuple[int, int]


def _cross(ax: int | Fraction, ay: int | Fraction,
           bx: int | Fraction, by: int | Fraction) -> int | Fraction:
    return ax * by - ay * bx


def _orient(a: IntPoint, b: IntPoint, c: IntPoint) -> int:
    return _cross(b[0] - a[0], b[1] - a[1],
                  c[0] - a[0], c[1] - a[1])


def _on_segment(a: IntPoint, b: IntPoint, p: IntPoint) -> bool:
    return (_orient(a, b, p) == 0
            and min(a[0], b[0]) <= p[0] <= max(a[0], b[0])
            and min(a[1], b[1]) <= p[1] <= max(a[1], b[1]))


def _segments_intersect(a: IntPoint, b: IntPoint,
                        c: IntPoint, d: IntPoint) -> bool:
    o1, o2 = _orient(a, b, c), _orient(a, b, d)
    o3, o4 = _orient(c, d, a), _orient(c, d, b)
    if (o1 > 0 > o2 or o2 > 0 > o1) and (o3 > 0 > o4 or o4 > 0 > o3):
        return True
    return ((o1 == 0 and _on_segment(a, b, c))
            or (o2 == 0 and _on_segment(a, b, d))
            or (o3 == 0 and _on_segment(c, d, a))
            or (o4 == 0 and _on_segment(c, d, b)))


def _polygon_valid(poly: list[IntPoint]) -> bool:
    n = len(poly)
    if len(set(poly)) != n:
        return False
    area2 = sum(poly[i][0] * poly[(i + 1) % n][1]
                - poly[i][1] * poly[(i + 1) % n][0] for i in range(n))
    if area2 <= 0:
        return False
    for i in range(n):
        if _orient(poly[i - 1], poly[i], poly[(i + 1) % n]) == 0:
            return False
        for j in range(i + 1, n):
            if j == i + 1 or (i == 0 and j == n - 1):
                continue
            if _segments_intersect(poly[i], poly[(i + 1) % n],
                                   poly[j], poly[(j + 1) % n]):
                return False
    return True


def _decode(values: Sequence[int] | None, input_is_null: bool,
            input_length: int | None) -> tuple[list[IntPoint], list[IntPoint]] | None:
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple))
            or not 2 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
            or any(type(value) is not int or not _I64_MIN <= value <= _I64_MAX
                   for value in values)):
        return None
    if input_length is not None and (
            type(input_length) is not int or input_length != len(values)):
        return None
    na, nb = values[0], values[1]
    if not MIN_VERTICES <= na <= MAX_VERTICES or not MIN_VERTICES <= nb <= MAX_VERTICES:
        return None
    if len(values) != 2 + 2 * na + 2 * nb:
        return None
    coords = values[2:]
    if any(not -COORDINATE_LIMIT <= value <= COORDINATE_LIMIT for value in coords):
        return None
    split = 2 * na
    a = [(coords[i], coords[i + 1]) for i in range(0, split, 2)]
    b = [(coords[i], coords[i + 1]) for i in range(split, len(coords), 2)]
    if not _polygon_valid(a) or not _polygon_valid(b):
        return None
    return a, b


def _inside(point: Point, poly: list[IntPoint]) -> bool:
    x, y = point
    winding = 0
    for i, a in enumerate(poly):
        b = poly[(i + 1) % len(poly)]
        side = _cross(b[0] - a[0], b[1] - a[1], x - a[0], y - a[1])
        if a[1] <= y < b[1] and side > 0:
            winding += 1
        elif b[1] <= y < a[1] and side < 0:
            winding -= 1
    return winding != 0


def _intersection(a: IntPoint, b: IntPoint,
                  c: IntPoint, d: IntPoint) -> tuple[Fraction, Fraction, Point]:
    rx, ry = b[0] - a[0], b[1] - a[1]
    sx, sy = d[0] - c[0], d[1] - c[1]
    den = _cross(rx, ry, sx, sy)
    t = Fraction(_cross(c[0] - a[0], c[1] - a[1], sx, sy), den)
    u = Fraction(_cross(c[0] - a[0], c[1] - a[1], rx, ry), den)
    return t, u, (Fraction(a[0]) + t * rx, Fraction(a[1]) + t * ry)


def _point_at(a: IntPoint, b: IntPoint, t: Fraction) -> Point:
    return (Fraction(a[0]) + t * (b[0] - a[0]),
            Fraction(a[1]) + t * (b[1] - a[1]))


def _canonicalize(rings: list[list[Point]]) -> list[list[Point]]:
    result: list[list[Point]] = []
    for ring in rings:
        compact: list[Point] = []
        for point in ring:
            if not compact or compact[-1] != point:
                compact.append(point)
        if len(compact) > 1 and compact[0] == compact[-1]:
            compact.pop()
        if len(compact) < 3:
            continue
        pivot = min(range(len(compact)), key=lambda i: compact[i])
        result.append(compact[pivot:] + compact[:pivot])
    result.sort(key=lambda ring: tuple(ring))
    return result


def _walk_interleaved(a: list[IntPoint], b: list[IntPoint]) -> list[list[Point]] | None:
    crossings: list[dict[str, object]] = []
    a_events: list[list[tuple[Fraction, int]]] = [[] for _ in a]
    b_events: list[list[tuple[Fraction, int]]] = [[] for _ in b]
    for i, p in enumerate(a):
        p2 = a[(i + 1) % len(a)]
        for j, q in enumerate(b):
            q2 = b[(j + 1) % len(b)]
            if not _segments_intersect(p, p2, q, q2):
                continue
            o1, o2 = _orient(p, p2, q), _orient(p, p2, q2)
            o3, o4 = _orient(q, q2, p), _orient(q, q2, p2)
            if not ((o1 > 0 > o2 or o2 > 0 > o1)
                    and (o3 > 0 > o4 or o4 > 0 > o3)):
                return None
            ta, tb, point = _intersection(p, p2, q, q2)
            cid = len(crossings)
            crossings.append({"point": point, "a_edge": i, "a_t": ta,
                              "b_edge": j, "b_t": tb})
            a_events[i].append((ta, cid))
            b_events[j].append((tb, cid))

    if not crossings:
        if _inside((Fraction(a[0][0]), Fraction(a[0][1])), b):
            return [[(Fraction(x), Fraction(y)) for x, y in a]]
        if _inside((Fraction(b[0][0]), Fraction(b[0][1])), a):
            return [[(Fraction(x), Fraction(y)) for x, y in b]]
        return []

    def classify(poly: list[IntPoint], other: list[IntPoint],
                 events: list[list[tuple[Fraction, int]]], key: str) -> None:
        for edge, edge_events in enumerate(events):
            edge_events.sort()
            p, q = poly[edge], poly[(edge + 1) % len(poly)]
            ts = [Fraction(0), *(t for t, _ in edge_events), Fraction(1)]
            for local, (t, cid) in enumerate(edge_events):
                before = _inside(_point_at(p, q, (ts[local] + ts[local + 1]) / 2), other)
                after = _inside(_point_at(p, q, (ts[local + 1] + ts[local + 2]) / 2), other)
                crossings[cid][key + "_entry"] = not before and after
                crossings[cid][key + "_exit"] = before and not after

    classify(a, b, a_events, "a")
    classify(b, a, b_events, "b")
    if any(c.get("a_entry") == c.get("b_entry") for c in crossings):
        return None

    def make_nodes(poly: list[IntPoint], events: list[list[tuple[Fraction, int]]]) -> tuple[list[tuple[Point, int]], dict[int, int]]:
        nodes: list[tuple[Point, int]] = []
        indices: dict[int, int] = {}
        for edge, p in enumerate(poly):
            nodes.append(((Fraction(p[0]), Fraction(p[1])), -1))
            q = poly[(edge + 1) % len(poly)]
            for t, cid in sorted(events[edge]):
                indices[cid] = len(nodes)
                nodes.append((crossings[cid]["point"], cid))  # type: ignore[arg-type]
        return nodes, indices

    nodes_a, index_a = make_nodes(a, a_events)
    nodes_b, index_b = make_nodes(b, b_events)
    visited: set[int] = set()
    rings: list[list[Point]] = []
    starts = sorted((index_a[cid], cid) for cid, c in enumerate(crossings)
                    if c["a_entry"])
    for start_index, start_cid in starts:
        if start_cid in visited:
            continue
        ring: list[Point] = [nodes_a[start_index][0]]
        visited.add(start_cid)
        active = "a"
        index = start_index
        guard = 0
        while True:
            guard += 1
            if guard > 2 * len(crossings) + len(a) + len(b) + 1:
                return None
            nodes = nodes_a if active == "a" else nodes_b
            next_index = (index + 1) % len(nodes)
            point, cid = nodes[next_index]
            ring.append(point)
            if cid >= 0:
                crossing = crossings[cid]
                exits = bool(crossing[active + "_exit"])
                if active == "a" and cid == start_cid:
                    ring.pop()
                    break
                if exits:
                    if cid == start_cid:
                        ring.pop()
                        break
                    visited.add(cid)
                    active = "b" if active == "a" else "a"
                    # Switch to the matching node on the other boundary.
                    index = (index_b if active == "b" else index_a)[cid]
                    continue
            index = next_index
        rings.append(ring)
    if len(visited) != len(crossings):
        return None
    return rings


def _serialize(rings: list[list[Point]]) -> bytes:
    canonical = _canonicalize(rings)
    words = [len(canonical)]
    for ring in canonical:
        words.append(len(ring))
        for x, y in ring:
            words.extend((x.numerator, x.denominator, y.numerator, y.denominator))
    return b"".join(word.to_bytes(8, "little", signed=True) for word in words)


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or capacity is not None and (type(capacity) is not int or capacity < 0)
            or input_length is not None and (type(input_length) is not int
                                              or not 0 <= input_length <= MAX_PARSEABLE_INPUT_LENGTH)
            or input_is_null and values not in (None, [], ())
            or not input_is_null and values is not None and input_length is not None
            and (not isinstance(values, (list, tuple)) or input_length != len(values))):
        return INVALID_RESULT, b""
    if input_is_null or values is None:
        return INVALID_RESULT, b""
    decoded = _decode(values, input_is_null, input_length)
    if decoded is None:
        return INVALID_RESULT, b""
    a, b = decoded
    rings = _walk_interleaved(a, b)
    if rings is None:
        return INVALID_RESULT, b""
    staged = _serialize(rings)
    if len(staged) > MAX_OUTPUT_BYTES:
        return INVALID_RESULT, b""
    if output_is_null or capacity is not None and capacity < len(staged):
        return OUTPUT_ERROR, b""
    return len(staged), staged
