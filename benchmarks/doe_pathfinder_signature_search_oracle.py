"""Independent state-space reference for DOE PathFinder signature search."""

from __future__ import annotations

from collections import deque


MAX_NODES = 10
MAX_EDGES = 100
MAX_SIGNATURE_LENGTH = 4
MAX_LABEL = 7


def doe_pathfinder_signature_search(values: list[int]) -> int:
    """Return whether a directed path visits the requested labels in order."""
    if len(values) < 3:
        return -2
    node_count, edge_count, signature_length = values[:3]
    if not 1 <= node_count <= MAX_NODES:
        return -2
    if not 0 <= edge_count <= min(MAX_EDGES, node_count * node_count):
        return -2
    if not 2 <= signature_length <= MAX_SIGNATURE_LENGTH:
        return -2
    if len(values) != 3 + 2 * edge_count + node_count + signature_length:
        return -2

    adjacency: list[list[int]] = [[] for _ in range(node_count)]
    seen_edges: set[tuple[int, int]] = set()
    for edge_index in range(edge_count):
        source = values[3 + 2 * edge_index]
        target = values[4 + 2 * edge_index]
        if not 0 <= source < node_count or not 0 <= target < node_count:
            return -2
        edge = (source, target)
        if edge in seen_edges:
            return -2
        seen_edges.add(edge)
        adjacency[source].append(target)

    labels_start = 3 + 2 * edge_count
    labels = values[labels_start : labels_start + node_count]
    signature = values[labels_start + node_count :]
    if any(label < -1 or label > MAX_LABEL for label in labels):
        return -2
    if any(label < 0 or label > MAX_LABEL for label in signature):
        return -2

    # Explore product states rather than copying the package's recursive DFS.
    # A matching node may either consume the next signature label or be
    # traversed past while searching for a later occurrence of that label.
    queue: deque[tuple[int, int]] = deque()
    seen_states: set[tuple[int, int]] = set()
    for node, label in enumerate(labels):
        if label == signature[0]:
            state = (node, 1)
            queue.append(state)
            seen_states.add(state)

    while queue:
        node, next_label = queue.popleft()
        for target in adjacency[node]:
            if labels[target] == signature[next_label]:
                if next_label + 1 == signature_length:
                    return 1
                advanced = (target, next_label + 1)
                if advanced not in seen_states:
                    seen_states.add(advanced)
                    queue.append(advanced)
            continuing = (target, next_label)
            if continuing not in seen_states:
                seen_states.add(continuing)
                queue.append(continuing)
    return 0

