"""Independent deterministic oracle for the bounded centroid-decomposition contract."""

from __future__ import annotations

import struct

MAX_NODES = 64
MAX_INPUT_LENGTH = 2 * MAX_NODES - 1
OUTPUT_BYTES_PER_NODE = 4
MAX_OUTPUT_BYTES = MAX_NODES * OUTPUT_BYTES_PER_NODE


def expected_output(values: list[int] | tuple[int, ...]) -> tuple[int, bytes]:
    if (not isinstance(values, (list, tuple)) or not 1 <= len(values) <= MAX_INPUT_LENGTH
            or any(type(value) is not int or not -(2**63) <= value < 2**63 for value in values)):
        return -1, b""

    node_count = values[0]
    if not 1 <= node_count <= MAX_NODES or len(values) != 2 * node_count - 1:
        return -1, b""

    adjacency = [[] for _ in range(node_count)]
    dsu = list(range(node_count))
    for offset in range(1, len(values), 2):
        left, right = values[offset], values[offset + 1]
        if not 0 <= left < node_count or not 0 <= right < node_count or left == right:
            return -1, b""

        left_root, right_root = left, right
        while dsu[left_root] != left_root:
            left_root = dsu[left_root]
        while dsu[right_root] != right_root:
            right_root = dsu[right_root]
        if left_root == right_root:
            return -1, b""
        dsu[right_root] = left_root
        adjacency[left].append(right)
        adjacency[right].append(left)

    parents = [-2] * node_count
    removed = [False] * node_count
    components = [(0, -1)]
    while components:
        start, centroid_parent = components.pop()

        # This intentionally finds each candidate's largest remaining branch by
        # traversing the component after removing that candidate. The ports use
        # subtree sizes, so the oracle does not share their centroid-selection walk.
        component = []
        stack = [start]
        seen = {start}
        while stack:
            node = stack.pop()
            component.append(node)
            for neighbor in adjacency[node]:
                if not removed[neighbor] and neighbor not in seen:
                    seen.add(neighbor)
                    stack.append(neighbor)

        best_node = -1
        best_largest_branch = node_count + 1
        for candidate in component:
            largest_branch = 0
            for first in adjacency[candidate]:
                if removed[first]:
                    continue
                branch_size = 0
                branch_stack = [(first, candidate)]
                while branch_stack:
                    node, previous = branch_stack.pop()
                    branch_size += 1
                    for neighbor in adjacency[node]:
                        if neighbor != previous and neighbor != candidate and not removed[neighbor]:
                            branch_stack.append((neighbor, node))
                largest_branch = max(largest_branch, branch_size)

            if (largest_branch < best_largest_branch
                    or (largest_branch == best_largest_branch and candidate < best_node)):
                best_node = candidate
                best_largest_branch = largest_branch

        parents[best_node] = centroid_parent
        removed[best_node] = True
        for neighbor in adjacency[best_node]:
            if not removed[neighbor]:
                components.append((neighbor, best_node))

    output = b"".join(struct.pack("<i", parent) for parent in parents)
    return node_count, output
