"""Weighted-graph Louvain profile with exact bounded modularity scores."""

from __future__ import annotations

from collections.abc import Sequence

MAX_VERTICES = 8
MAX_EDGES = MAX_VERTICES * (MAX_VERTICES - 1) // 2
MAX_EDGE_WEIGHT = 7
MAX_VALID_INPUT_LENGTH = 2 + 3 * MAX_EDGES
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
LABEL_BITS = 3
LABEL_SHIFT = 24
MAX_RESULT = (MAX_VERTICES << LABEL_SHIFT) | ((1 << (LABEL_BITS * MAX_VERTICES)) - 1)
INVALID_RESULT = -1


def _parse(values: Sequence[int] | None, input_is_null: bool,
           input_length: int | None) -> tuple[int, list[list[int]]] | None:
    if type(input_is_null) is not bool or input_is_null or not isinstance(values, (list, tuple)):
        return None
    length = len(values) if input_length is None else input_length
    if (type(length) is not int or length < 2 or length > MAX_PARSEABLE_INPUT_LENGTH
            or length != len(values)):
        return None
    if any(type(value) is not int or not -(1 << 63) <= value < (1 << 63) for value in values):
        return None
    vertex_count, edge_count = values[:2]
    if (not 2 <= vertex_count <= MAX_VERTICES or not 1 <= edge_count <= MAX_EDGES
            or length != 2 + 3 * edge_count):
        return None

    matrix = [[0] * vertex_count for _ in range(vertex_count)]
    previous_pair: tuple[int, int] | None = None
    offset = 2
    for _ in range(edge_count):
        source, target, weight = values[offset:offset + 3]
        offset += 3
        if (not 0 <= source < target < vertex_count
                or not 1 <= weight <= MAX_EDGE_WEIGHT):
            return None
        pair = (source, target)
        if previous_pair is not None and pair <= previous_pair:
            return None
        previous_pair = pair
        matrix[source][target] = weight
        matrix[target][source] = weight
    return vertex_count, matrix


def _score(matrix: list[list[int]], communities: list[int]) -> int:
    degrees = [sum(row) for row in matrix]
    total_degree = sum(degrees)
    total_by_community: dict[int, int] = {}
    internal_directed = 0
    size = len(communities)
    for vertex, community in enumerate(communities):
        total_by_community[community] = total_by_community.get(community, 0) + degrees[vertex]
        for neighbor in range(size):
            if communities[neighbor] == community:
                internal_directed += matrix[vertex][neighbor]
    return total_degree * internal_directed - sum(value * value for value in total_by_community.values())


def _community_key(community: int, communities: list[int], roots: list[int]) -> int:
    return min(roots[index] for index, label in enumerate(communities) if label == community)


def _packed_result(vertex_count: int, communities: list[int], roots: list[int],
                   members: list[int]) -> int:
    labels_by_community: dict[int, int] = {}
    for index, community in enumerate(communities):
        root = roots[index]
        previous = labels_by_community.get(community)
        if previous is None or root < previous:
            labels_by_community[community] = root
    labels = [0] * vertex_count
    for index, member_mask in enumerate(members):
        label = labels_by_community[communities[index]]
        for vertex in range(vertex_count):
            if member_mask & (1 << vertex):
                labels[vertex] = label
    code = sum(label << (LABEL_BITS * vertex) for vertex, label in enumerate(labels))
    count = len(set(communities))
    return (count << LABEL_SHIFT) | code


def expected_result(values: Sequence[int] | None, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    parsed = _parse(values, input_is_null, input_length)
    if parsed is None:
        return INVALID_RESULT
    vertex_count, matrix = parsed
    roots = list(range(vertex_count))
    members = [1 << vertex for vertex in range(vertex_count)]
    node_count = vertex_count

    while True:
        communities = list(range(node_count))
        current_score = _score(matrix, communities)
        moved_at_level = False
        while True:
            moved_in_sweep = False
            for vertex in range(node_count):
                source_community = communities[vertex]
                candidate_communities: set[int] = set()
                for neighbor in range(node_count):
                    target = communities[neighbor]
                    if (neighbor != vertex and matrix[vertex][neighbor] > 0
                            and target != source_community):
                        candidate_communities.add(target)
                if not candidate_communities:
                    continue

                best_community: int | None = None
                best_score = current_score
                best_key: int | None = None
                for target in sorted(candidate_communities,
                                     key=lambda item: _community_key(item, communities, roots)):
                    communities[vertex] = target
                    candidate_score = _score(matrix, communities)
                    communities[vertex] = source_community
                    target_key = _community_key(target, communities, roots)
                    if (candidate_score > best_score
                            or (candidate_score == best_score and candidate_score > current_score
                                and (best_key is None or target_key < best_key))):
                        best_community = target
                        best_score = candidate_score
                        best_key = target_key
                if best_community is not None:
                    communities[vertex] = best_community
                    current_score = best_score
                    moved_at_level = True
                    moved_in_sweep = True
            if not moved_in_sweep:
                break

        if not moved_at_level:
            return _packed_result(vertex_count, communities, roots, members)

        old_labels = sorted(set(communities), key=lambda item: _community_key(item, communities, roots))
        label_to_index = {label: index for index, label in enumerate(old_labels)}
        new_count = len(old_labels)
        if new_count >= node_count:
            return _packed_result(vertex_count, communities, roots, members)
        new_matrix = [[0] * new_count for _ in range(new_count)]
        new_roots = [0] * new_count
        new_members = [0] * new_count
        for old_index, label in enumerate(communities):
            new_index = label_to_index[label]
            if new_members[new_index] == 0:
                new_roots[new_index] = roots[old_index]
            else:
                new_roots[new_index] = min(new_roots[new_index], roots[old_index])
            new_members[new_index] |= members[old_index]
        for source in range(node_count):
            new_source = label_to_index[communities[source]]
            for target in range(node_count):
                new_target = label_to_index[communities[target]]
                new_matrix[new_source][new_target] += matrix[source][target]
        matrix = new_matrix
        roots = new_roots
        members = new_members
        node_count = new_count
