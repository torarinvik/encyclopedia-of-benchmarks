"""Offline sweep with an active y-ordered set of noncrossing segments."""

from __future__ import annotations

from collections.abc import Sequence

MIN_COORD = -300
MAX_COORD = 300
MAX_N = 16
MAX_M = 24
MAX_Q = 16
MAX_FACES = 16
MAX_VALID_LENGTH = 4 + 2 * MAX_N + 3 * MAX_M + 2 * MAX_Q
MAX_PARSEABLE_LENGTH = MAX_VALID_LENGTH + 1
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1


def _orientation(a: tuple[int, int], b: tuple[int, int], c: tuple[int, int]) -> int:
    return (b[0] - a[0]) * (c[1] - a[1]) - (b[1] - a[1]) * (c[0] - a[0])


def _on_segment(a: tuple[int, int], b: tuple[int, int], p: tuple[int, int]) -> bool:
    return (min(a[0], b[0]) <= p[0] <= max(a[0], b[0])
            and min(a[1], b[1]) <= p[1] <= max(a[1], b[1]))


def _intersects(a: tuple[int, int], b: tuple[int, int],
                c: tuple[int, int], d: tuple[int, int]) -> bool:
    o1, o2 = _orientation(a, b, c), _orientation(a, b, d)
    o3, o4 = _orientation(c, d, a), _orientation(c, d, b)
    if o1 == 0 and _on_segment(a, b, c): return True
    if o2 == 0 and _on_segment(a, b, d): return True
    if o3 == 0 and _on_segment(c, d, a): return True
    if o4 == 0 and _on_segment(c, d, b): return True
    return (o1 < 0 < o2 or o2 < 0 < o1) and (o3 < 0 < o4 or o4 < 0 < o3)


def _decode(values: Sequence[int] | None, input_length: int | None,
            input_is_null: bool) -> tuple[list[tuple[int, int]],
                                          list[tuple[int, int, int]],
                                          list[tuple[int, int]], int] | None:
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple))
            or not 4 <= len(values) <= MAX_PARSEABLE_LENGTH
            or any(type(value) is not int or not I64_MIN <= value <= I64_MAX
                   for value in values)):
        return None
    if input_length is not None and (
            type(input_length) is not int or input_length != len(values)):
        return None
    n, m, q, face_count = values[:4]
    if not 2 <= n <= MAX_N or not 1 <= m <= MAX_M or not 0 <= q <= MAX_Q or not 1 <= face_count <= MAX_FACES:
        return None
    if len(values) != 4 + 2 * n + 3 * m + 2 * q:
        return None
    cursor = 4
    points: list[tuple[int, int]] = []
    used_x: set[int] = set()
    for _ in range(n):
        x, y = values[cursor:cursor + 2]
        cursor += 2
        if not MIN_COORD <= x <= MAX_COORD or not MIN_COORD <= y <= MAX_COORD or x in used_x:
            return None
        used_x.add(x)
        points.append((x, y))
    edges: list[tuple[int, int, int]] = []
    seen_edges: set[tuple[int, int]] = set()
    for _ in range(m):
        u, v, above_face = values[cursor:cursor + 3]
        cursor += 3
        if (not 0 <= u < n or not 0 <= v < n or u == v
                or not -1 <= above_face < face_count):
            return None
        key = (min(u, v), max(u, v))
        if key in seen_edges:
            return None
        seen_edges.add(key)
        edges.append((u, v, above_face))
    for i, (u, v, _) in enumerate(edges):
        a, b = points[u], points[v]
        for x, y, _ in edges[:i]:
            c, d = points[x], points[y]
            shared = {u, v}.intersection((x, y))
            if shared:
                if len(shared) != 1:
                    return None
                common = points[next(iter(shared))]
                other_a = a if a != common else b
                other_b = c if c != common else d
                if _orientation(common, other_a, other_b) == 0:
                    return None
            elif _intersects(a, b, c, d):
                return None
    queries: list[tuple[int, int]] = []
    for _ in range(q):
        x, y = values[cursor:cursor + 2]
        cursor += 2
        if (not MIN_COORD <= x <= MAX_COORD or not MIN_COORD <= y <= MAX_COORD
                or x in used_x):
            return None
        queries.append((x, y))
    return points, edges, queries, face_count


def _edge_endpoints(points: list[tuple[int, int]], edge: tuple[int, int, int]) -> tuple[tuple[int, int], tuple[int, int]]:
    a, b = points[edge[0]], points[edge[1]]
    return (a, b) if a[0] < b[0] else (b, a)


def _height_num_den(points: list[tuple[int, int]], edge: tuple[int, int, int], x: int) -> tuple[int, int]:
    left, right = _edge_endpoints(points, edge)
    dx = right[0] - left[0]
    return left[1] * dx + (right[1] - left[1]) * (x - left[0]), dx


def _edge_less_at_x(points: list[tuple[int, int]], edges: list[tuple[int, int, int]],
                    first: int, second: int, x: int) -> bool:
    n1, d1 = _height_num_den(points, edges[first], x)
    n2, d2 = _height_num_den(points, edges[second], x)
    if n1 * d2 != n2 * d1:
        return n1 * d2 < n2 * d1
    a1, b1 = _edge_endpoints(points, edges[first])
    a2, b2 = _edge_endpoints(points, edges[second])
    slope1 = (b1[1] - a1[1]) * (b2[0] - a2[0])
    slope2 = (b2[1] - a2[1]) * (b1[0] - a1[0])
    if slope1 != slope2: return slope1 < slope2
    return first < second


def _answer_query(points: list[tuple[int, int]], edges: list[tuple[int, int, int]],
                  active: list[int], x: int, y: int, face_count: int) -> int:
    low, high = 0, len(active)
    while low < high:
        middle = (low + high) // 2
        numerator, denominator = _height_num_den(points, edges[active[middle]], x)
        if numerator < y * denominator: low = middle + 1
        else: high = middle
    if low < len(active):
        numerator, denominator = _height_num_den(points, edges[active[low]], x)
        if numerator == y * denominator:
            return face_count + active[low] + 1
    if low == 0:
        return 0
    face = edges[active[low - 1]][2]
    return face + 1 if face >= 0 else 0


def expected_output(values: Sequence[int] | None, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    decoded = _decode(values, input_length, input_is_null)
    if decoded is None:
        return -1
    points, edges, queries, face_count = decoded
    events: list[tuple[int, int, int]] = []  # x, remove/add/query, edge or query id
    for edge_id, edge in enumerate(edges):
        left, right = _edge_endpoints(points, edge)
        events.append((left[0], 1, edge_id))
        events.append((right[0], 0, edge_id))
    for query_id, (x, _) in enumerate(queries):
        events.append((x, 2, query_id))
    events.sort()

    active: list[int] = []
    answers = [0] * len(queries)
    for x, event_type, item_id in events:
        if event_type == 0:
            active.remove(item_id)
        elif event_type == 1:
            low, high = 0, len(active)
            while low < high:
                middle = (low + high) // 2
                if _edge_less_at_x(points, edges, active[middle], item_id, x): low = middle + 1
                else: high = middle
            active.insert(low, item_id)
        else:
            answers[item_id] = _answer_query(points, edges, active, x,
                                             queries[item_id][1], face_count)
    return sum((i + 1) * answer for i, answer in enumerate(answers))
