"""Independent rotation-scan reference for modified-Yao selections."""

from __future__ import annotations

MAX_N, MAX_M, K = 16, 42, 14
MAX_FRAME = 2 + MAX_N + 7 * MAX_M
WORKSPACE_BYTES = 16384


def _read(frame, is_null=False, length=None):
    if (type(is_null) is not bool or is_null or not isinstance(frame, (list, tuple))
            or len(frame) > MAX_FRAME + 1
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63) for value in frame)):
        return None
    if length is not None and (type(length) is not int or length != len(frame)):
        return None
    if len(frame) < 2:
        return None
    n, m = frame[0], frame[1]
    if not 3 <= n <= MAX_N or not n - 1 <= m <= min(MAX_M, 3 * n - 6):
        return None
    if len(frame) != 2 + 5 * m + n + 2 * m:
        return None
    records = []
    endpoint_cone = {}
    adjacency = [[] for _ in range(n)]
    cursor = 2
    last_uv = None
    for eid in range(m):
        u, v, w2, cu, cv = frame[cursor:cursor + 5]
        cursor += 5
        if (not 0 <= u < v < n or not 1 <= w2 <= 10**12
                or not 0 <= cu < K or not 0 <= cv < K
                or (last_uv is not None and (u, v) <= last_uv)):
            return None
        last_uv = (u, v)
        records.append((u, v, w2))
        endpoint_cone[2 * eid] = cu
        endpoint_cone[2 * eid + 1] = cv
        adjacency[u].append(v)
        adjacency[v].append(u)

    rotations = []
    owner = {}
    for vertex in range(n):
        degree = frame[cursor]
        cursor += 1
        if degree != len(adjacency[vertex]) or not 1 <= degree <= MAX_M:
            return None
        order = tuple(frame[cursor:cursor + degree])
        cursor += degree
        if len(order) != degree:
            return None
        previous = -1
        for dart in order:
            if not 0 <= dart < 2 * m or dart in owner:
                return None
            u, v, _ = records[dart // 2]
            source = u if dart % 2 == 0 else v
            cone = endpoint_cone[dart]
            if source != vertex or cone < previous:
                return None
            previous = cone
            owner[dart] = (vertex, len(order))
        rotations.append(order)
    if cursor != len(frame) or len(owner) != 2 * m:
        return None

    seen = {0}
    frontier = [0]
    while frontier:
        u = frontier.pop()
        for v in adjacency[u]:
            if v not in seen:
                seen.add(v)
                frontier.append(v)
    if len(seen) != n:
        return None

    location = {}
    for v, order in enumerate(rotations):
        for j, dart in enumerate(order):
            location[dart] = (v, j)
    visited = set()
    face_count = 0
    for dart in range(2 * m):
        if dart in visited:
            continue
        face_count += 1
        current = dart
        while current not in visited:
            visited.add(current)
            twin = current ^ 1
            dest = records[current // 2][1] if current % 2 == 0 else records[current // 2][0]
            row = rotations[dest]
            current = row[(location[twin][1] - 1) % len(row)]
        if current != dart:
            return None
    if n - m + face_count != 2:
        return None
    return n, m, records, endpoint_cone, rotations


def expected_result(values, input_is_null=False, input_length=None):
    decoded = _read(values, input_is_null, input_length)
    if decoded is None:
        return -1
    n, m, edges, edge_cones, rotation = decoded
    chosen = set()

    # Compute ordinary per-cone winners from a flat scan of each rotation.
    for vertex in range(n):
        best = {}
        for dart in rotation[vertex]:
            cone = edge_cones[dart]
            eid = dart // 2
            candidate = (edges[eid][2], eid, dart)
            if cone not in best or candidate < best[cone]:
                best[cone] = candidate
        chosen.update(record[2] for record in best.values())

    for vertex in range(n):
        row = rotation[vertex]
        present = {edge_cones[dart] for dart in row}
        if not present:
            continue
        runs = []
        for cone in range(K):
            before = (cone - 1) % K
            if cone not in present or before in present:
                continue
            span = 0
            while span < K and (cone + span) % K not in present:
                span += 1
            runs.append((cone, span))
        for start, span in runs:
            if span == 1:
                cw_cone, ccw_cone = (start - 1) % K, (start + 1) % K
                cw = next(d for d in reversed(row) if edge_cones[d] == cw_cone)
                ccw = next(d for d in row if edge_cones[d] == ccw_cone)
                if cw in chosen:
                    chosen.add(ccw)
                elif ccw in chosen:
                    chosen.add(cw)
                else:
                    def rank(dart):
                        return edges[dart // 2][2], dart // 2
                    chosen.add(min((cw, ccw), key=rank))
                continue

            need_cw, need_ccw = span // 2, (span + 1) // 2
            # Locate the first clockwise dart adjacent to the gap, then scan
            # the raw cyclic rotation rather than a cone-bucket representation.
            prior_cone = (start - 1) % K
            first_cw = next(i for i in range(len(row) - 1, -1, -1)
                            if edge_cones[row[i]] == prior_cone)
            for step in range(len(row)):
                if not need_cw:
                    break
                dart = row[(first_cw - step) % len(row)]
                if dart not in chosen:
                    chosen.add(dart)
                    need_cw -= 1
            next_cone = (start + span) % K
            first_ccw = next(i for i, dart in enumerate(row) if edge_cones[dart] == next_cone)
            for step in range(len(row)):
                if not need_ccw:
                    break
                dart = row[(first_ccw + step) % len(row)]
                if dart not in chosen:
                    chosen.add(dart)
                    need_ccw -= 1

    result = 0
    for eid in range(m):
        if 2 * eid in chosen and 2 * eid + 1 in chosen:
            result |= 1 << eid
    return result
