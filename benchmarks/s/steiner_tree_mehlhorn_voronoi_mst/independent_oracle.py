"""Independent all-terminal relaxation and exhaustive spanning-tree oracle."""
from __future__ import annotations

import itertools
import struct
from collections.abc import Sequence

MAX_N = 8
MAX_M = 14
MAX_VALID_INPUT_LENGTH = 3 + MAX_N + 3 * MAX_M
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_OUTPUT_BYTES = 8 * (2 + MAX_N - 1)
MAX_WORKSPACE_BYTES = 8192
WORKSPACE_BYTES = MAX_WORKSPACE_BYTES
SYMBOL = "steiner_tree_mehlhorn_voronoi_mst"
INF = 1 << 60


def _decode(values: Sequence[int]):
    if not 3 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH:
        return None
    for value in values:
        if type(value) is not int or value < -(1 << 63) or value >= (1 << 63):
            return None
    n, m, k = values[0], values[1], values[2]
    if n < 2 or n > MAX_N or m < 1 or m > MAX_M or k < 2 or k > n:
        return None
    end_term = 3 + k
    if len(values) < end_term + 3 * m:
        return None
    terminals = list(values[3:end_term])
    if len(set(terminals)) != k or any(t < 0 or t >= n for t in terminals):
        return None
    edges = []
    pairs = set()
    pos = end_term
    for edge_id in range(m):
        u, v, weight = values[pos:pos + 3]
        pos += 3
        if u < 0 or u >= v or v >= n or weight < 1 or weight > 9:
            return None
        if (u, v) in pairs:
            return None
        pairs.add((u, v))
        edges.append((u, v, weight))
    if pos != len(values):
        return None
    seen = {0}
    while True:
        old = len(seen)
        for u, v, _ in edges:
            if u in seen:
                seen.add(v)
            if v in seen:
                seen.add(u)
        if len(seen) == old:
            break
    if len(seen) != n:
        return None
    return n, m, terminals, edges


def _all_terminal_paths(n, terminals, edges):
    all_dist = {}
    all_pred = {}
    # Bellman-Ford relaxation is intentionally independent of the primary's
    # multi-source Dijkstra. Positive edge weights make predecessor distances
    # strictly decrease when following a selected predecessor backward.
    for source in terminals:
        dist = [INF] * n
        dist[source] = 0
        for _ in range(n - 1):
            changed = False
            for edge_id, (u, v, w) in enumerate(edges):
                if dist[u] != INF and dist[u] + w < dist[v]:
                    dist[v] = dist[u] + w
                    changed = True
                if dist[v] != INF and dist[v] + w < dist[u]:
                    dist[u] = dist[v] + w
                    changed = True
            if not changed:
                break
        pred = [-1] * n
        pred_edge = [-1] * n
        for v in range(n):
            if v == source or dist[v] == INF:
                continue
            options = []
            for edge_id, (u, z, w) in enumerate(edges):
                if z == v and dist[u] + w == dist[v]:
                    options.append((u, edge_id))
                elif u == v and dist[z] + w == dist[v]:
                    options.append((z, edge_id))
            if not options:
                return None
            pred[v], pred_edge[v] = min(options)
        all_dist[source] = dist
        all_pred[source] = (pred, pred_edge)
    return all_dist, all_pred


def _components(vertices, edges):
    parent = list(range(vertices))
    def find(x):
        while parent[x] != x:
            parent[x] = parent[parent[x]]
            x = parent[x]
        return x
    def join(a, b):
        a, b = find(a), find(b)
        if a == b:
            return False
        parent[b] = a
        return True
    return find, join


def _enumerated_tree(vertices, candidates, wanted_vertices=None):
    # candidates are `(cost, key, edge_id, u, v)` and already have canonical
    # IDs. Exhaustively choose an acyclic connected subset, breaking equal
    # totals by the sorted candidate-order tuple (the Kruskal basis tie).
    if wanted_vertices is None:
        wanted_vertices = list(range(vertices))
    needed = len(wanted_vertices) - 1
    if needed < 0 or len(candidates) < needed:
        return None
    best = None
    for indices in itertools.combinations(range(len(candidates)), needed):
        parent = list(range(vertices))
        def find(x):
            while parent[x] != x:
                parent[x] = parent[parent[x]]
                x = parent[x]
            return x
        total = 0
        valid = True
        for ix in indices:
            cost, _, _, u, v = candidates[ix]
            ru, rv = find(u), find(v)
            if ru == rv:
                valid = False
                break
            parent[rv] = ru
            total += cost
        if not valid or any(find(v) != find(wanted_vertices[0]) for v in wanted_vertices):
            continue
        key = (total, indices)
        if best is None or key < best[0]:
            best = (key, [candidates[ix][2] for ix in indices])
    return None if best is None else best[1]


def _solve(data):
    n, m, terminals, edges = data
    paths = _all_terminal_paths(n, terminals, edges)
    if paths is None:
        return None
    all_dist, all_pred = paths
    owner = []
    for v in range(n):
        owner.append(min((all_dist[t][v], t) for t in terminals)[1])

    by_pair = {}
    for edge_id, (u, v, weight) in enumerate(edges):
        tu, tv = owner[u], owner[v]
        if tu == tv:
            continue
        if tu < tv:
            a, b, left, right = tu, tv, u, v
        else:
            a, b, left, right = tv, tu, v, u
        cand_weight = all_dist[a][left] + weight + all_dist[b][right]
        value = (cand_weight, a, b, left, right, edge_id)
        old = by_pair.get((a, b))
        if old is None or value < old:
            by_pair[(a, b)] = value
    candidates = sorted((w, (a, b, left, right, eid), eid, a, b)
                        for (a, b), (w, a, b, left, right, eid) in by_pair.items())
    selected_ix = _enumerated_tree(n, candidates, terminals)
    if selected_ix is None:
        return None
    # Rebuild the terminal tree candidates selected by exhaustive enumeration.
    selected = [candidates[i] for i in range(len(candidates)) if candidates[i][2] in selected_ix]
    # Candidate edge IDs are unique because an original edge belongs to one
    # pair, and there is one retained crossing witness per terminal pair.
    used = set()
    for cost, key, edge_id, a, b in selected:
        _, _, left, right, _ = key
        used.add(edge_id)
        pred_a, pe_a = all_pred[a]
        x = left
        while x != a:
            if pe_a[x] < 0:
                return None
            used.add(pe_a[x])
            x = pred_a[x]
        pred_b, pe_b = all_pred[b]
        x = right
        while x != b:
            if pe_b[x] < 0:
                return None
            used.add(pe_b[x])
            x = pred_b[x]

    active = set(terminals)
    for edge_id in used:
        active.update(edges[edge_id][:2])
    union_candidates = sorted((edges[e][2], (e,), e, edges[e][0], edges[e][1]) for e in used)
    tree = _enumerated_tree(n, union_candidates, sorted(active))
    if tree is None:
        return None
    keep = set(tree)
    degree = [0] * n
    incident = [[] for _ in range(n)]
    for edge_id in tree:
        u, v, _ = edges[edge_id]
        degree[u] += 1
        degree[v] += 1
        incident[u].append(edge_id)
        incident[v].append(edge_id)
    terminal_set = set(terminals)
    queue = [v for v in range(n) if v not in terminal_set and degree[v] <= 1]
    for u in queue:
        if degree[u] > 1:
            continue
        for edge_id in incident[u]:
            if edge_id not in keep:
                continue
            keep.remove(edge_id)
            a, b, _ = edges[edge_id]
            v = b if a == u else a
            degree[u] -= 1
            degree[v] -= 1
            if v not in terminal_set and degree[v] <= 1:
                queue.append(v)
    result = sorted(keep)
    if not result:
        return None
    return sum(edges[e][2] for e in result), result


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if type(output_is_null) is not bool or type(input_is_null) is not bool:
        return -1, b""
    if capacity is not None and (type(capacity) is not int or capacity < 0):
        return -1, b""
    if input_length is not None and (type(input_length) is not int or
                                     not 0 <= input_length <= MAX_PARSEABLE_INPUT_LENGTH):
        return -1, b""
    if input_is_null or values is None or not isinstance(values, (list, tuple)):
        return -1, b""
    if input_length is not None and input_length != len(values):
        return -1, b""
    data = _decode(values)
    if data is None:
        return -1, b""
    answer = _solve(data)
    if answer is None:
        return -1, b""
    cost, edges = answer
    payload = struct.pack("<" + "q" * (2 + len(edges)), cost, len(edges), *edges)
    if output_is_null or (capacity is not None and capacity < len(payload)):
        return -2, b""
    return len(payload), payload
