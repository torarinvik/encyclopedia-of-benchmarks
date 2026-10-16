"""Reference for Java ConnectedComponent.Graph.countGraphs()."""

from __future__ import annotations

MAX_VERTEX_ID = 63
MAX_EDGE_COUNT = 64
MAX_NODE_COUNT = 128
MAX_INPUT_LENGTH = 1 + 2 * MAX_EDGE_COUNT
I64_MIN, I64_MAX = -(1 << 63), (1 << 63) - 1
INVALID_RESULT = -1


def expected_result(values: list[int] | tuple[int, ...]) -> int:
    """Count roots in the source's ordered outgoing-DFS forest."""
    if (not isinstance(values, (list, tuple)) or not 1 <= len(values) <= MAX_INPUT_LENGTH + 1
            or any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values)):
        return INVALID_RESULT

    edge_count = values[0]
    if (not 0 <= edge_count <= MAX_EDGE_COUNT
            or len(values) != 1 + 2 * edge_count):
        return INVALID_RESULT

    labels: list[int] = []
    last_node_for_label: dict[int, int] = {}
    edge_starts: list[int] = []
    edge_ends: list[int] = []

    def add_node(label: int) -> int:
        node = len(labels)
        labels.append(label)
        last_node_for_label[label] = node
        return node

    for offset in range(1, len(values), 2):
        start_label, end_label = values[offset:offset + 2]
        if not 0 <= start_label <= MAX_VERTEX_ID or not 0 <= end_label <= MAX_VERTEX_ID:
            return INVALID_RESULT

        if start_label == end_label:
            start = last_node_for_label.get(start_label)
            if start is None:
                start = add_node(start_label)
            end = add_node(end_label)
        else:
            start = last_node_for_label.get(start_label)
            end = last_node_for_label.get(end_label)
            if start is None:
                start = add_node(start_label)
            if end is None:
                end = add_node(end_label)
        edge_starts.append(start)
        edge_ends.append(end)

    node_count = len(labels)
    if node_count > MAX_NODE_COUNT:
        return INVALID_RESULT

    marked = [False] * node_count
    component_count = 0
    for root in range(node_count):
        if marked[root]:
            continue
        visited = [False] * node_count

        def visit(current: int) -> None:
            visited[current] = True
            for edge in range(edge_count):
                destination = edge_ends[edge]
                if edge_starts[edge] == current and not visited[destination]:
                    visit(destination)

        visit(root)
        for node, was_visited in enumerate(visited):
            if was_visited:
                marked[node] = True
        component_count += 1

    return component_count
