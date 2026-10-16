"""Reference for the Go depth-first search target-route benchmark."""

from __future__ import annotations

MAX_NODES = 64
MAX_EDGES = 94
MAX_INPUT_LENGTH = 4 + MAX_NODES + 2 * MAX_EDGES
MAX_LABEL = 255
MAX_OUTPUT_BYTES = 128
INVALID_RESULT = -2
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1


def expected_output(values: tuple[int, ...] | list[int]) -> tuple[int, bytes]:
    """Return the stack-pop route through the target, or an empty result."""
    if (not isinstance(values, (tuple, list)) or len(values) < 5
            or len(values) > MAX_INPUT_LENGTH
            or any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values)):
        return INVALID_RESULT, b""

    node_count, start_label, target_label = values[:3]
    if not 1 <= node_count <= MAX_NODES or not 0 <= start_label <= MAX_LABEL or not 0 <= target_label <= MAX_LABEL:
        return INVALID_RESULT, b""
    edge_count_position = 3 + node_count
    if edge_count_position >= len(values):
        return INVALID_RESULT, b""
    labels = list(values[3:edge_count_position])
    if (len(labels) != node_count
            or any(not 0 <= label <= MAX_LABEL for label in labels)
            or len(set(labels)) != node_count
            or start_label not in labels):
        return INVALID_RESULT, b""

    edge_count = values[edge_count_position]
    if (not 0 <= edge_count <= MAX_EDGES
            or len(values) != edge_count_position + 1 + 2 * edge_count):
        return INVALID_RESULT, b""

    label_index = {label: index for index, label in enumerate(labels)}
    adjacency = [0] * node_count
    for offset in range(edge_count_position + 1, len(values), 2):
        left, right = values[offset:offset + 2]
        if left not in label_index or right not in label_index:
            return INVALID_RESULT, b""
        left_index = label_index[left]
        right_index = label_index[right]
        adjacency[left_index] |= 1 << right_index
        adjacency[right_index] |= 1 << left_index

    stack = [label_index[start_label]]
    route: list[int] = []
    while stack:
        current = stack.pop()
        route.append(labels[current])
        for neighbor in range(node_count):
            bit = 1 << neighbor
            if adjacency[current] & bit and neighbor not in stack:
                stack.append(neighbor)
            adjacency[current] &= ~bit
            adjacency[neighbor] &= ~(1 << current)
        if route[-1] == target_label:
            if len(route) > MAX_OUTPUT_BYTES:
                return INVALID_RESULT, b""
            return len(route), bytes(route)
    return 0, b""
