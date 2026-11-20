"""Face-DSU reference for the fixed-embedding clustered planarity criterion."""

from __future__ import annotations

from collections import deque
from collections.abc import Sequence

MAX_N = 8
MAX_M = 18
MAX_VALID_INPUT_LENGTH = 54
MAX_PARSEABLE_INPUT_LENGTH = 55
WORKSPACE_BYTES = 8192


def _parse(values: Sequence[int] | None, input_is_null: bool,
           input_length: int | None):
    if (type(input_is_null) is not bool or input_is_null or values is None
            or not isinstance(values, (list, tuple))
            or not 4 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
            or (input_length is not None
                and (type(input_length) is not int or input_length != len(values)))
            or any(type(x) is not int or not -(1 << 63) <= x < (1 << 63) for x in values)):
        return None
    n, count, outer_u, outer_v = values[:4]
    if not 3 <= n <= MAX_N or not 0 <= count <= n - 2:
        return None
    offset = 4
    rows: list[list[int]] = []
    adj = [[False] * n for _ in range(n)]
    degree_sum = 0
    for u in range(n):
        if offset >= len(values):
            return None
        degree = values[offset]
        offset += 1
        if not 1 <= degree < n or offset + degree > len(values):
            return None
        row = list(values[offset:offset + degree])
        offset += degree
        if (len(set(row)) != degree
                or any(not 0 <= v < n or v == u for v in row)):
            return None
        rows.append(row)
        degree_sum += degree
        for v in row:
            adj[u][v] = True
    if degree_sum % 2 or offset + count != len(values):
        return None
    m = degree_sum // 2
    if not 1 <= m <= MAX_M or any(adj[u][v] != adj[v][u]
                                  for u in range(n) for v in range(n)):
        return None
    edges = [(u, v) for u in range(n) for v in range(u + 1, n) if adj[u][v]]
    if len(edges) != m or not (0 <= outer_u < n and 0 <= outer_v < n
                               and outer_u != outer_v and adj[outer_u][outer_v]):
        return None

    seen = {0}
    queue = deque([0])
    while queue:
        u = queue.popleft()
        for v in range(n):
            if adj[u][v] and v not in seen:
                seen.add(v)
                queue.append(v)
    if len(seen) != n:
        return None

    masks = list(values[offset:offset + count])
    full = (1 << n) - 1
    if (len(set(masks)) != count
            or any(mask <= 0 or mask >= full or mask.bit_count() < 2 for mask in masks)):
        return None
    for i, left in enumerate(masks):
        for right in masks[i + 1:]:
            common = left & right
            if common and common != left and common != right:
                return None
    for mask in masks:
        start = next((v for v in range(n) if mask >> v & 1), -1)
        reached = {start}
        todo = [start]
        while todo:
            u = todo.pop()
            for v in range(n):
                if mask >> v & 1 and adj[u][v] and v not in reached:
                    reached.add(v)
                    todo.append(v)
        if len(reached) != mask.bit_count():
            return None

    # Build every face orbit of the supplied clockwise rotation system.
    face_of: dict[tuple[int, int], int] = {}
    faces = 0
    for u, v in edges:
        for first, second in ((u, v), (v, u)):
            if (first, second) in face_of:
                continue
            start = (first, second)
            dart = start
            local: set[tuple[int, int]] = set()
            while dart not in local:
                a, b = dart
                if not adj[a][b] or dart in face_of:
                    return None
                local.add(dart)
                row = rows[b]
                dart = (b, row[(row.index(a) + 1) % len(row)])
            if dart != start:
                return None
            for a, b in local:
                face_of[(a, b)] = faces
            faces += 1
    if len(face_of) != 2 * m or faces != m - n + 2:
        return None
    return n, m, rows, adj, edges, masks, face_of, face_of[(outer_u, outer_v)]


def _root(parent: list[int], item: int) -> int:
    while parent[item] != item:
        parent[item] = parent[parent[item]]
        item = parent[item]
    return item


def _criterion(parsed) -> int:
    n, m, rows, adj, edges, masks, face_of, outer_face = parsed
    face_count = m - n + 2
    for mask in masks:
        parent = list(range(face_count))
        for u, v in edges:
            if not (mask >> u & 1 and mask >> v & 1):
                a = _root(parent, face_of[(u, v)])
                b = _root(parent, face_of[(v, u)])
                parent[a] = b
        outside_root = _root(parent, outer_face)
        for vertex in range(n):
            if mask >> vertex & 1:
                continue
            incident = [face_of[(vertex, v)] for v in range(n) if adj[vertex][v]]
            if not incident or any(_root(parent, face) != outside_root for face in incident):
                return 0
        for u, v in edges:
            if mask >> u & 1 and mask >> v & 1:
                continue
            if _root(parent, face_of[(u, v)]) != outside_root:
                return 0
    return 1


def expected_result(values: Sequence[int] | None, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    parsed = _parse(values, input_is_null, input_length)
    return -1 if parsed is None else _criterion(parsed)
