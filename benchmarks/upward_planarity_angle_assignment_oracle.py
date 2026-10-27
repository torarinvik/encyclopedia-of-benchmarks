"""Primary flow-model oracle for fixed-embedding upward-planarity DOI 653."""
from __future__ import annotations

import struct
from collections import deque
from collections.abc import Sequence

MAX_N = 8
MAX_M = 18
MAX_F = 12
MAX_INPUT_LENGTH = 4 + 6 * MAX_M + MAX_F
MAX_OUTPUT_VALUES = 2 + 3 * MAX_N
MAX_OUTPUT_BYTES = MAX_OUTPUT_VALUES * 8


def _decode(values: Sequence[int] | None):
    if (not isinstance(values, (list, tuple)) or not 4 <= len(values) <= MAX_INPUT_LENGTH
            or any(type(x) is not int or not -(1 << 63) <= x < (1 << 63) for x in values)):
        return None
    n, m, fcount, outer = values[:4]
    if not 2 <= n <= MAX_N or not 1 <= m <= min(MAX_M, 3 * n - 6) or not 1 <= fcount <= MAX_F or not 0 <= outer < fcount:
        return None
    edge_end = 4 + 2 * m
    if len(values) < edge_end + fcount:
        return None
    arcs: list[tuple[int, int]] = []
    undirected: set[tuple[int, int]] = set()
    for i in range(m):
        u, v = values[4 + 2 * i:6 + 2 * i]
        if not 0 <= u < n or not 0 <= v < n or u == v:
            return None
        if arcs and arcs[-1] >= (u, v):
            return None
        key = (min(u, v), max(u, v))
        if key in undirected:
            return None
        undirected.add(key)
        arcs.append((u, v))
    arc_set = set(arcs)
    faces: list[list[tuple[int, int]]] = []
    cursor = edge_end
    seen_darts: set[tuple[int, int]] = set()
    if len(values) != 4 + 6 * m + fcount:
        return None
    for _ in range(fcount):
        length = values[cursor]; cursor += 1
        if length < 1 or cursor + 2 * length > len(values):
            return None
        walk = []
        for j in range(length):
            u, v = values[cursor:cursor + 2]; cursor += 2
            if (u, v) not in arc_set and (v, u) not in arc_set:
                return None
            if (u, v) in seen_darts:
                return None
            seen_darts.add((u, v)); walk.append((u, v))
        if any(walk[i][1] != walk[(i + 1) % length][0] for i in range(length)):
            return None
        faces.append(walk)
    if cursor != len(values) or len(seen_darts) != 2 * m:
        return None
    for u, v in arcs:
        if (u, v) not in seen_darts or (v, u) not in seen_darts:
            return None
    if n - m + fcount != 2:
        return None
    return n, arcs, faces, outer


def _analyze(n: int, arcs: list[tuple[int, int]], faces: list[list[tuple[int, int]]], outer: int):
    out = [set() for _ in range(n)]
    und = [set() for _ in range(n)]
    indeg = [0] * n
    for u, v in arcs:
        out[u].add(v); und[u].add(v); und[v].add(u); indeg[v] += 1
    # Connectedness and acyclicity.
    reached = {0}; stack = [0]
    while stack:
        u = stack.pop()
        for v in und[u] - reached:
            reached.add(v); stack.append(v)
    if len(reached) != n:
        return None
    degree = indeg[:]; queue = deque(v for v in range(n) if degree[v] == 0); removed = 0
    while queue:
        u = queue.popleft(); removed += 1
        for v in out[u]:
            degree[v] -= 1
            if degree[v] == 0: queue.append(v)
    if removed != n:
        return None
    # Face corners induce each vertex's cyclic rotation successor relation.
    successor = [dict() for _ in range(n)]
    corner_indices: list[dict[int, int]] = [dict() for _ in range(n)]
    switch_counts = [[0, 0] for _ in faces]
    incident_faces = [set() for _ in range(n)]
    for fi, walk in enumerate(faces):
        for i, (_, v) in enumerate(walk):
            w = walk[(i + 1) % len(walk)][1]
            u = walk[i][0]
            if u in successor[v]: return None
            successor[v][u] = w
            if v not in corner_indices[fi]: corner_indices[fi][v] = i
            incident_faces[v].add(fi)
            incoming_edge = out[v].__contains__(u)
            outgoing_edge = out[v].__contains__(w)
            if incoming_edge and outgoing_edge: switch_counts[fi][0] += 1
            elif not incoming_edge and not outgoing_edge: switch_counts[fi][1] += 1
    for v in range(n):
        nbrs = und[v]
        if len(successor[v]) != len(nbrs) or set(successor[v]) != nbrs or set(successor[v].values()) != nbrs:
            return None
        if nbrs:
            cur = min(nbrs); seen = set()
            while cur not in seen:
                seen.add(cur); cur = successor[v][cur]
            if cur != min(nbrs) or len(seen) != len(nbrs): return None
            transitions = 0
            for a in nbrs:
                b = successor[v][a]
                if (a in out[v]) != (b in out[v]): transitions += 1
            if transitions not in (0, 2): return None
    terminals = [v for v in range(n) if indeg[v] == 0 or not out[v]]
    capacities = []
    for fi, (s, t) in enumerate(switch_counts):
        if s != t: return None
        capacities.append(s + 1 if fi == outer else s - 1)
    return terminals, incident_faces, corner_indices, capacities


def _compute(decoded) -> list[int] | None:
    n, arcs, faces, outer = decoded
    analyzed = _analyze(n, arcs, faces, outer)
    if analyzed is None: return None
    terminals, incidence, corners, caps = analyzed
    r = len(terminals)
    result = [1, r]
    if any(c < 0 for c in caps) or sum(caps) != r:
        return [0, r] + [-1, -1, -1] * r
    # Fix terminals in vertex order. Choose the smallest incident face that
    # leaves a feasible residual matching, yielding a canonical face vector.
    remaining = caps[:]
    selected = [-1] * r
    def residual_feasible(first: int) -> bool:
        slots = [face for face, count in enumerate(remaining) for _ in range(count)]
        owner = [-1] * len(slots)
        def augment(ti: int, seen: set[int]) -> bool:
            v = terminals[ti]
            for si, face in enumerate(slots):
                if face not in incidence[v] or si in seen: continue
                seen.add(si)
                if owner[si] < 0 or augment(owner[si], seen):
                    owner[si] = ti
                    return True
            return False
        return all(augment(ti, set()) for ti in range(first, r))
    for ti, vertex in enumerate(terminals):
        chosen = -1
        for face in sorted(incidence[vertex]):
            if remaining[face] <= 0: continue
            remaining[face] -= 1
            if residual_feasible(ti + 1):
                chosen = face
                break
            remaining[face] += 1
        if chosen < 0: return [0, r] + [-1, -1, -1] * r
        selected[ti] = chosen
    for ti, _ in enumerate(selected):
        face = selected[ti]
        result.extend((terminals[ti], face, corners[face][terminals[ti]]))
    return result


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or capacity is not None and (type(capacity) is not int or capacity < 0)
            or input_length is not None and (type(input_length) is not int or input_length < 0)
            or input_is_null and values not in (None, [], ())
            or not input_is_null and values is not None and input_length is not None and input_length != len(values)):
        return -1, b""
    decoded = None if input_is_null else _decode(values)
    if decoded is None: return -1, b""
    words = _compute(decoded)
    if words is None: return -1, b""
    payload = struct.pack("<" + "q" * len(words), *words)
    if output_is_null or capacity is not None and capacity < len(payload): return -2, b""
    return len(payload), payload
