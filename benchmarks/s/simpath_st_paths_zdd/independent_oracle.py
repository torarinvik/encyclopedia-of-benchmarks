"""Explicit simple-path enumeration followed by family-based ZDD reduction."""

from functools import lru_cache

from .primary_oracle import PATH_COUNT_RADIX, _parse


def expected_result(values):
    parsed = _parse(values)
    if parsed is None:
        return -1
    n, edges, source, target = parsed
    adjacency = [[] for _ in range(n)]
    for edge_index, (u, v) in enumerate(edges):
        adjacency[u].append((v, edge_index))
        adjacency[v].append((u, edge_index))

    paths = []

    def enumerate_paths(vertex, visited, edge_mask):
        if vertex == target:
            paths.append(edge_mask)
            return
        for neighbor, edge_index in adjacency[vertex]:
            bit = 1 << neighbor
            if visited & bit == 0:
                enumerate_paths(neighbor, visited | bit, edge_mask | (1 << edge_index))

    enumerate_paths(source, 1 << source, 0)
    family = tuple(sorted(set(paths)))
    unique = {}

    @lru_cache(maxsize=None)
    def build(edge_index, residual_family):
        if not residual_family:
            return 0
        if edge_index == len(edges):
            return 1 if residual_family == (0,) else 0
        bit = 1 << edge_index
        low_family = tuple(mask for mask in residual_family if mask & bit == 0)
        high_family = tuple(mask ^ bit for mask in residual_family if mask & bit != 0)
        low = build(edge_index + 1, low_family)
        high = build(edge_index + 1, high_family)
        if high == 0:
            return low
        key = edge_index, low, high
        if key not in unique:
            unique[key] = len(unique) + 2
        return unique[key]

    root = build(0, family)
    # The unique table is built from recursive subfamilies; count nodes reachable
    # from the root so the result is independent of memo/unique-table debris.
    by_id = {identifier: key for key, identifier in unique.items()}
    reachable = set()
    stack = [root]
    while stack:
        identifier = stack.pop()
        if identifier <= 1 or identifier in reachable:
            continue
        reachable.add(identifier)
        _, low, high = by_id[identifier]
        stack.extend((low, high))
    return len(reachable) * PATH_COUNT_RADIX + len(paths)
