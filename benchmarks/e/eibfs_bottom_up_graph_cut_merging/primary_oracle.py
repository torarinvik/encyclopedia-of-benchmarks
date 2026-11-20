"""Bounded PEIBFS: adaptive block merging with fresh EIBFS component solves."""

from __future__ import annotations

from collections.abc import Sequence

try:
    from benchmarks.eibfs_maxflow_oracle import expected_result as eibfs_result
except ImportError:  # Imported as benchmarks.e.eibfs_bottom_up_graph_cut_merging.
    from ...eibfs_maxflow_oracle import expected_result as eibfs_result

MIN_VERTICES = 2
MAX_VERTICES = 6
MAX_BOUNDARY_RECORDS = 6
MAX_BLOCKS = 4
MAX_CAPACITY = 7
MAX_VALID_INPUT_LENGTH = 3 + 3 * MAX_VERTICES + 4 * MAX_BOUNDARY_RECORDS
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_RESULT = MAX_VERTICES * MAX_CAPACITY


def _parse(values: Sequence[int] | None, input_is_null: bool,
           input_length: int | None):
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple))
            or not 3 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
            or any(type(x) is not int or not -(1 << 63) <= x < (1 << 63)
                   for x in values)
            or input_length is not None
            and (type(input_length) is not int or input_length != len(values))):
        return None
    n, m, block_count = values[:3]
    if (not MIN_VERTICES <= n <= MAX_VERTICES
            or not 0 <= m <= MAX_BOUNDARY_RECORDS
            or not 1 <= block_count <= min(n, MAX_BLOCKS)
            or len(values) != 3 + 3 * n + 4 * m):
        return None
    block_ids = list(values[3:3 + n])
    if (any(not 0 <= b < block_count for b in block_ids)
            or set(block_ids) != set(range(block_count))):
        return None
    source_caps = list(values[3 + n:3 + 2 * n])
    sink_caps = list(values[3 + 2 * n:3 + 3 * n])
    if any(not 0 <= c <= MAX_CAPACITY for c in source_caps + sink_caps):
        return None
    edges = []
    offset = 3 + 3 * n
    for i in range(m):
        u, v, uv, vu = values[offset + 4 * i:offset + 4 * i + 4]
        if (not 0 <= u < n or not 0 <= v < n or u == v
                or not 0 <= uv <= MAX_CAPACITY or not 0 <= vu <= MAX_CAPACITY):
            return None
        edges.append((u, v, uv, vu))
    return n, block_count, block_ids, source_caps, sink_caps, edges


def _canonical_cut_tags(vertices: list[int], source_caps: list[int],
                        sink_caps: list[int], edges: list[tuple[int, int, int, int]]) -> dict[int, int]:
    """Choose the numerically smallest source-side mask among minimum cuts."""
    best_cost = None
    best_mask = 0
    size = len(vertices)
    local = {vertex: index for index, vertex in enumerate(vertices)}
    for mask in range(1 << size):
        cost = 0
        for u in vertices:
            source_side = bool(mask & (1 << local[u]))
            cost += sink_caps[u] if source_side else source_caps[u]
        for u, v, uv, vu in edges:
            if u not in local or v not in local:
                continue
            u_side = bool(mask & (1 << local[u]))
            v_side = bool(mask & (1 << local[v]))
            if u_side and not v_side:
                cost += uv
            elif v_side and not u_side:
                cost += vu
        if best_cost is None or cost < best_cost or (cost == best_cost and mask < best_mask):
            best_cost, best_mask = cost, mask
    return {u: (1 if best_mask & (1 << local[u]) else 2) for u in vertices}


def _eibfs_component(vertices: list[int], source_caps: list[int],
                     sink_caps: list[int], edges: list[tuple[int, int, int, int]]) -> int:
    """Serialize one original-capacity component and solve it with EIBFS."""
    local = {vertex: index for index, vertex in enumerate(vertices)}
    count = 2 * len(vertices) + 2 * sum(u in local and v in local for u, v, _, _ in edges)
    source, sink = len(vertices), len(vertices) + 1
    frame = [len(vertices) + 2, count, source, sink]
    for u in vertices:
        frame.extend((source, local[u], source_caps[u]))
        frame.extend((local[u], sink, sink_caps[u]))
    for u, v, uv, vu in edges:
        if u in local and v in local:
            frame.extend((local[u], local[v], uv))
            frame.extend((local[v], local[u], vu))
    return eibfs_result(frame, False, len(frame))


def expected_result(values: Sequence[int] | None, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    parsed = _parse(values, input_is_null, input_length)
    if parsed is None:
        return -1
    n, block_count, block_ids, source_caps, sink_caps, edges = parsed

    tags: dict[int, int] = {}
    component_flow = [0] * block_count
    for block in range(block_count):
        vertices = [u for u in range(n) if block_ids[u] == block]
        local_edges = [edge for edge in edges
                       if block_ids[edge[0]] == block and block_ids[edge[1]] == block]
        tags.update(_canonical_cut_tags(vertices, source_caps, sink_caps, local_edges))
        component_flow[block] = _eibfs_component(vertices, source_caps, sink_caps, local_edges)

    boundary = []
    potential: dict[tuple[int, int], int] = {}
    for u, v, uv, vu in edges:
        a, b = block_ids[u], block_ids[v]
        if a == b or not (uv or vu):
            continue
        pair = (min(a, b), max(a, b))
        boundary.append((a, b, u, v, uv, vu))
        potential.setdefault(pair, 0)
        if tags[u] != tags[v]:
            potential[pair] += int(uv > 0) + int(vu > 0)
    ordered_pairs = sorted(potential, key=lambda pair: (-potential[pair], pair))

    parent = list(range(block_count))

    def find(block: int) -> int:
        while parent[block] != block:
            parent[block] = parent[parent[block]]
            block = parent[block]
        return block

    for a, b in ordered_pairs:
        root_a, root_b = find(a), find(b)
        if root_a == root_b:
            continue
        root, other = min(root_a, root_b), max(root_a, root_b)
        parent[other] = root
        vertices = [u for u in range(n) if find(block_ids[u]) == root]
        component_flow[root] = _eibfs_component(vertices, source_caps, sink_caps, edges)
        component_flow[other] = 0

    return sum(component_flow[b] for b in range(block_count) if find(b) == b)
