"""Dual-BFS reference for the bounded supplied-embedding criterion check."""

from __future__ import annotations

from collections import deque
from collections.abc import Sequence

MAX_N = 8
MAX_VALID_INPUT_LENGTH = 54
MAX_PARSEABLE_INPUT_LENGTH = 55


def _decode(words: Sequence[int] | None, is_null: bool, declared_length: int | None):
    if (type(is_null) is not bool or is_null or words is None
            or not isinstance(words, (tuple, list))
            or len(words) < 4 or len(words) > MAX_PARSEABLE_INPUT_LENGTH
            or declared_length is not None
            and (type(declared_length) is not int or declared_length != len(words))
            or any(type(x) is not int or not -(1 << 63) <= x < (1 << 63) for x in words)):
        return None
    n, c, outer_from, outer_to = words[:4]
    if n < 3 or n > MAX_N or c < 0 or c > n - 2:
        return None
    cursor = 4
    rotations: list[tuple[int, ...]] = []
    adjacency = [set() for _ in range(n)]
    darts: list[tuple[int, int]] = []
    for vertex in range(n):
        if cursor >= len(words):
            return None
        degree = words[cursor]
        cursor += 1
        if degree < 1 or degree >= n or cursor + degree > len(words):
            return None
        row = tuple(words[cursor:cursor + degree])
        cursor += degree
        if (len(set(row)) != degree or any(v < 0 or v >= n or v == vertex for v in row)):
            return None
        rotations.append(row)
        adjacency[vertex].update(row)
    if cursor + c != len(words):
        return None
    masks = tuple(words[cursor:])
    edges = [(u, v) for u in range(n) for v in adjacency[u] if u < v]
    if any(v not in adjacency[u] for u in range(n) for v in adjacency[u]):
        return None
    if not 1 <= len(edges) <= 18 or not (0 <= outer_from < n and 0 <= outer_to < n
                                         and outer_to in adjacency[outer_from]):
        return None
    reach = {0}
    pending = [0]
    while pending:
        u = pending.pop()
        for v in adjacency[u] - reach:
            reach.add(v)
            pending.append(v)
    if len(reach) != n:
        return None
    full = (1 << n) - 1
    if (len(set(masks)) != c
            or any(mask <= 0 or mask >= full or mask.bit_count() < 2 for mask in masks)):
        return None
    for i, mask in enumerate(masks):
        for other in masks[i + 1:]:
            intersection = mask & other
            if intersection and intersection not in (mask, other):
                return None
        members = [v for v in range(n) if mask >> v & 1]
        seen = {members[0]}
        pending = [members[0]]
        while pending:
            u = pending.pop()
            for v in adjacency[u]:
                if mask >> v & 1 and v not in seen:
                    seen.add(v)
                    pending.append(v)
        if len(seen) != len(members):
            return None

    # Enumerate the directed face boundary for each dart, retaining the full
    # sequence so this reference builds its dual adjacency independently.
    face_id: dict[tuple[int, int], int] = {}
    face_edges: list[list[tuple[int, int]]] = []
    for u, v in edges:
        for dart0 in ((u, v), (v, u)):
            if dart0 in face_id:
                continue
            sequence: list[tuple[int, int]] = []
            dart = dart0
            while dart not in sequence:
                a, b = dart
                if b not in adjacency[a] or dart in face_id:
                    return None
                sequence.append(dart)
                row = rotations[b]
                try:
                    index = row.index(a)
                except ValueError:
                    return None
                dart = (b, row[(index + 1) % len(row)])
            if dart != dart0:
                return None
            fid = len(face_edges)
            for edge_dart in sequence:
                face_id[edge_dart] = fid
            face_edges.append(sequence)
    m = len(edges)
    if len(face_id) != 2 * m or len(face_edges) != m - n + 2:
        return None
    return n, adjacency, edges, masks, face_id, face_id[(outer_from, outer_to)], len(face_edges)


def _bfs_criterion(parsed) -> int:
    n, adjacency, edges, masks, face_id, outer_face, face_count = parsed
    for cluster in masks:
        dual = [[] for _ in range(face_count)]
        for u, v in edges:
            if not (cluster >> u & 1 and cluster >> v & 1):
                left = face_id[(u, v)]
                right = face_id[(v, u)]
                dual[left].append(right)
                dual[right].append(left)
        reachable = {outer_face}
        queue = deque([outer_face])
        while queue:
            face = queue.popleft()
            for other in dual[face]:
                if other not in reachable:
                    reachable.add(other)
                    queue.append(other)
        for vertex in range(n):
            if cluster >> vertex & 1:
                continue
            if not all(face_id[(vertex, v)] in reachable for v in adjacency[vertex]):
                return 0
        for u, v in edges:
            if cluster >> u & 1 and cluster >> v & 1:
                continue
            if face_id[(u, v)] not in reachable:
                return 0
    return 1


def expected_result(values: Sequence[int] | None, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    parsed = _decode(values, input_is_null, input_length)
    return -1 if parsed is None else _bfs_criterion(parsed)
