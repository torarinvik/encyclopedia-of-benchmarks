"""Small independent rotation-system oracle and witness validator."""

from __future__ import annotations

from itertools import permutations, product


def _parse(values: list[int]) -> tuple[int, list[tuple[int, int]]] | None:
    if len(values) < 2:
        return None
    n, m = values[:2]
    if not (1 <= n <= 32 and 0 <= m <= 96) or len(values) != 2 + 2 * m:
        return None
    edges: list[tuple[int, int]] = []
    seen: set[tuple[int, int]] = set()
    for i in range(m):
        u, v = values[2 + 2 * i : 4 + 2 * i]
        if not (0 <= u < v < n) or (u, v) in seen:
            return None
        seen.add((u, v))
        edges.append((u, v))
    return n, edges


def exhaustive_planar_embedding(values: list[int]) -> tuple[bool, list[list[int]] | None] | None:
    """Exhaustively assign local cyclic orders; intended only for N<=6."""
    parsed = _parse(values)
    if parsed is None:
        return None
    n, edges = parsed
    if n > 6:
        return None
    adj = [[] for _ in range(n)]
    edge_of: dict[tuple[int, int], int] = {}
    for eid, (u, v) in enumerate(edges):
        adj[u].append(v)
        adj[v].append(u)
        edge_of[(u, v)] = edge_of[(v, u)] = eid
    for row in adj:
        row.sort()

    unseen = set(range(n))
    components: list[list[int]] = []
    while unseen:
        root = min(unseen)
        todo = [root]
        unseen.remove(root)
        component = []
        while todo:
            v = todo.pop()
            component.append(v)
            for w in adj[v]:
                if w in unseen:
                    unseen.remove(w)
                    todo.append(w)
        components.append(sorted(component))

    chosen: list[list[int]] = [row[:] for row in adj]
    for vertices in components:
        component_edges = sum(len(adj[v]) for v in vertices) // 2
        if len(vertices) >= 3 and component_edges > 3 * len(vertices) - 6:
            return False, None
        if len(vertices) == 1:
            continue
        options: list[list[tuple[int, ...]]] = []
        for v in vertices:
            row = adj[v]
            if len(row) <= 1:
                options.append([tuple(row)])
            else:
                anchor = row[0]
                options.append([(anchor, *tail) for tail in permutations(row[1:])])

        found = False
        for candidate in product(*options):
            rotation = {v: list(candidate[i]) for i, v in enumerate(vertices)}
            successor: dict[tuple[int, int], tuple[int, int]] = {}
            for v in vertices:
                row = rotation[v]
                for i, w in enumerate(row):
                    successor[(v, w)] = (v, row[(i + 1) % len(row)])
            used: set[tuple[int, int]] = set()
            faces = 0
            for u, v in edges:
                if u not in rotation:
                    continue
                for dart in ((u, v), (v, u)):
                    if dart in used:
                        continue
                    faces += 1
                    here = dart
                    while here not in used:
                        used.add(here)
                        at_v, from_v = here[1], here[0]
                        next_v, next_neighbor = successor[(at_v, from_v)]
                        here = (next_v, next_neighbor)
            if len(vertices) - component_edges + faces == 2:
                for v in vertices:
                    chosen[v] = rotation[v]
                found = True
                break
        if not found:
            return False, None
    return True, chosen


def validate_embedding(values: list[int], output: bytes) -> bool:
    """Check status byte, exact neighbor permutations, and Euler face counts."""
    parsed = _parse(values)
    if parsed is None or not output:
        return False
    n, edges = parsed
    if output[0] != 1 or len(output) != 1 + 2 * len(edges):
        return False
    at = 1
    rotation: list[list[int]] = []
    expected = [set() for _ in range(n)]
    for u, v in edges:
        expected[u].add(v)
        expected[v].add(u)
    for v in range(n):
        d = len(expected[v])
        row = list(output[at : at + d])
        at += d
        if len(row) != d or set(row) != expected[v] or len(set(row)) != d:
            return False
        rotation.append(row)

    successor: dict[tuple[int, int], tuple[int, int]] = {}
    for v, row in enumerate(rotation):
        for i, w in enumerate(row):
            successor[(v, w)] = (v, row[(i + 1) % len(row)])
    unseen = {tuple(d) for u, v in edges for d in ((u, v), (v, u))}
    component_of = [-1] * n
    components: list[list[int]] = []
    for root in range(n):
        if component_of[root] >= 0:
            continue
        cid = len(components)
        todo = [root]
        component_of[root] = cid
        component = []
        while todo:
            v = todo.pop()
            component.append(v)
            for w in expected[v]:
                if component_of[w] < 0:
                    component_of[w] = cid
                    todo.append(w)
        components.append(component)
    faces_by_component = [0] * len(components)
    while unseen:
        faces_by_component[component_of[next(iter(unseen))[0]]] += 1
        here = next(iter(unseen))
        while here in unseen:
            unseen.remove(here)
            v, w = here
            around = successor[(w, v)]
            here = (around[0], around[1])
    for cid, vertices in enumerate(components):
        edge_count = sum(len(expected[v]) for v in vertices) // 2
        if edge_count and len(vertices) - edge_count + faces_by_component[cid] != 2:
            return False
    return True


def validate_result(values: list[int], output: bytes) -> bool:
    """Validate a result, deciding negative cases exhaustively when bounded.

    A positive result carries its own combinatorial embedding certificate and
    is checked at any supported input size. A negative result is independently
    decided only for N<=6, where the distinct exhaustive rotation oracle is
    tractable and complete.
    """
    parsed = _parse(values)
    if parsed is None or not output:
        return False
    n, _ = parsed
    if output[0] == 1:
        return validate_embedding(values, output)
    if output[0] == 0 and len(output) == 1 and n <= 6:
        decision = exhaustive_planar_embedding(values)
        return decision is not None and not decision[0]
    return False


def oracle(values: list[int]) -> bool | None:
    result = exhaustive_planar_embedding(values)
    return None if result is None else result[0]
