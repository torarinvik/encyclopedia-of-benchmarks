"""Louvain replay retaining the original graph rather than quotient matrices."""

from __future__ import annotations

from collections.abc import Sequence

MAX_VERTICES = 8
MAX_EDGES = 28
MAX_EDGE_WEIGHT = 7
MAX_VALID_INPUT_LENGTH = 86
MAX_PARSEABLE_INPUT_LENGTH = 87
INVALID_RESULT = -1


def _decode(values: Sequence[int] | None, input_is_null: bool,
            input_length: int | None) -> tuple[int, list[list[int]]] | None:
    if type(input_is_null) is not bool or input_is_null or not isinstance(values, (list, tuple)):
        return None
    size = len(values) if input_length is None else input_length
    if type(size) is not int or size < 2 or size > MAX_PARSEABLE_INPUT_LENGTH or size != len(values):
        return None
    if any(type(item) is not int or not -(1 << 63) <= item < (1 << 63) for item in values):
        return None
    n, m = values[0], values[1]
    if not 2 <= n <= MAX_VERTICES or not 1 <= m <= MAX_EDGES or size != 2 + 3 * m:
        return None
    original = [[0] * n for _ in range(n)]
    previous: tuple[int, int] | None = None
    cursor = 2
    for _ in range(m):
        u, v, weight = values[cursor], values[cursor + 1], values[cursor + 2]
        cursor += 3
        if u < 0 or u >= v or v >= n or not 1 <= weight <= MAX_EDGE_WEIGHT:
            return None
        pair = (u, v)
        if previous is not None and pair <= previous:
            return None
        previous = pair
        original[u][v] = original[v][u] = weight
    return n, original


def _expand_labels(members: list[int], communities: list[int], n: int) -> list[int]:
    expanded = [-1] * n
    for node, member_mask in enumerate(members):
        for vertex in range(n):
            if member_mask & (1 << vertex):
                expanded[vertex] = communities[node]
    return expanded


def _original_score(original: list[list[int]], expanded: list[int]) -> int:
    degrees = [sum(row) for row in original]
    total_degree = sum(degrees)
    internal_directed = 0
    community_totals: dict[int, int] = {}
    for vertex, community in enumerate(expanded):
        community_totals[community] = community_totals.get(community, 0) + degrees[vertex]
        for neighbor in range(len(expanded)):
            if expanded[neighbor] == community:
                internal_directed += original[vertex][neighbor]
    return total_degree * internal_directed - sum(value * value for value in community_totals.values())


def _root_of(mask: int) -> int:
    for vertex in range(MAX_VERTICES):
        if mask & (1 << vertex):
            return vertex
    return MAX_VERTICES


def _pack(n: int, members: list[int], communities: list[int]) -> int:
    roots: dict[int, int] = {}
    for node, community in enumerate(communities):
        root = _root_of(members[node])
        if community not in roots or root < roots[community]:
            roots[community] = root
    labels = [0] * n
    for node, member_mask in enumerate(members):
        label = roots[communities[node]]
        for vertex in range(n):
            if member_mask & (1 << vertex):
                labels[vertex] = label
    code = sum(label << (3 * vertex) for vertex, label in enumerate(labels))
    return (len(set(communities)) << 24) | code


def expected_result(values: Sequence[int] | None, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    decoded = _decode(values, input_is_null, input_length)
    if decoded is None:
        return INVALID_RESULT
    n, original = decoded
    members = [1 << vertex for vertex in range(n)]

    while True:
        node_count = len(members)
        roots = [_root_of(mask) for mask in members]
        communities = list(range(node_count))
        expanded = _expand_labels(members, communities, n)
        current_score = _original_score(original, expanded)
        moved_at_level = False

        while True:
            moved_in_sweep = False
            for node in range(node_count):
                source = communities[node]
                neighboring_communities: set[int] = set()
                for other in range(node_count):
                    if other == node or communities[other] == source:
                        continue
                    cross_weight = 0
                    for u in range(n):
                        if not members[node] & (1 << u):
                            continue
                        for v in range(n):
                            if members[other] & (1 << v):
                                cross_weight += original[u][v]
                    if cross_weight > 0:
                        neighboring_communities.add(communities[other])
                if not neighboring_communities:
                    continue

                best_target: int | None = None
                best_score = current_score
                best_key: int | None = None
                ordered_targets = sorted(
                    neighboring_communities,
                    key=lambda target: min(roots[index] for index, label in enumerate(communities)
                                           if label == target),
                )
                for target in ordered_targets:
                    candidate_communities = communities.copy()
                    candidate_communities[node] = target
                    candidate_expanded = _expand_labels(members, candidate_communities, n)
                    candidate_score = _original_score(original, candidate_expanded)
                    target_key = min(roots[index] for index, label in enumerate(communities)
                                     if label == target)
                    if (candidate_score > best_score
                            or (candidate_score == best_score and candidate_score > current_score
                                and (best_key is None or target_key < best_key))):
                        best_target = target
                        best_score = candidate_score
                        best_key = target_key
                if best_target is not None:
                    communities[node] = best_target
                    expanded = _expand_labels(members, communities, n)
                    current_score = best_score
                    moved_at_level = True
                    moved_in_sweep = True
            if not moved_in_sweep:
                break

        if not moved_at_level:
            return _pack(n, members, communities)

        groups = sorted(set(communities), key=lambda target: min(
            roots[index] for index, label in enumerate(communities) if label == target))
        if len(groups) >= node_count:
            return _pack(n, members, communities)
        merged: list[int] = []
        for group in groups:
            mask = 0
            for node, label in enumerate(communities):
                if label == group:
                    mask |= members[node]
            merged.append(mask)
        members = merged
