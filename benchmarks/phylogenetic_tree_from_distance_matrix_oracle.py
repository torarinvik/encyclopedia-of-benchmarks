"""Bounded additive-tree reconstruction oracle for encyclopedia DOI 292."""

from __future__ import annotations

import struct
from collections import deque
from collections.abc import Sequence

MAX_N = 6
MAX_INPUT_LENGTH = 1 + MAX_N * MAX_N + 1
MAX_EDGES = 2 * MAX_N - 3
MAX_OUTPUT_BYTES = 8 * (1 + 2 * MAX_EDGES)
MAX_WORKSPACE_BYTES = 4096
INVALID_RESULT = -1
OUTPUT_ERROR = -2


def _decode(values: Sequence[int] | None) -> list[list[int]] | None:
    if (not isinstance(values, (list, tuple)) or not 1 <= len(values) <= MAX_INPUT_LENGTH
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return None
    n = values[0]
    if not 2 <= n <= MAX_N or len(values) != 1 + n * n:
        return None
    matrix = [list(values[1 + row * n : 1 + (row + 1) * n]) for row in range(n)]
    for i in range(n):
        if matrix[i][i] != 0:
            return None
        for j in range(n):
            if i != j and not 1 <= matrix[i][j] <= 32:
                return None
            if matrix[i][j] != matrix[j][i]:
                return None
    return matrix


def _tree_distance(n_nodes: int, edges: list[list[int]], start: int, target: int) -> int | None:
    parent = [-1] * n_nodes
    total = [0] * n_nodes
    queue = deque([start])
    parent[start] = start
    while queue:
        node = queue.popleft()
        if node == target:
            return total[node]
        for edge_index, edge in enumerate(edges):
            u, v, weight = edge
            if u == node:
                neighbor = v
            elif v == node:
                neighbor = u
            else:
                continue
            if parent[neighbor] != -1:
                continue
            parent[neighbor] = node
            total[neighbor] = total[node] + weight
            queue.append(neighbor)
    return None


def _reconstruct(matrix: list[list[int]]) -> list[tuple[int, int]] | None:
    """Insert leaves in prefix order, the unwind of the recursive reduction."""
    n = len(matrix)
    edges: list[list[int]] = [[0, 1, 2 * matrix[0][1]]]
    label_node = list(range(n))
    label_mask = [0] * (2 * n - 2)
    label_mask[0] = 1
    label_mask[1] = 2
    node_count = 2

    for leaf in range(2, n):
        limb2 = min(matrix[i][leaf] + matrix[j][leaf] - matrix[i][j]
                    for i in range(leaf) for j in range(i + 1, leaf))
        if limb2 < 0:
            return None
        witness = None
        for i in range(leaf):
            for j in range(i + 1, leaf):
                from_i2 = 2 * matrix[i][leaf] - limb2
                from_j2 = 2 * matrix[j][leaf] - limb2
                if from_i2 >= 0 and from_j2 >= 0 and 2 * matrix[i][j] == from_i2 + from_j2:
                    witness = (i, j, from_i2)
                    break
            if witness is not None:
                break
        if witness is None:
            return None
        i, j, attach_distance = witness
        start, target = label_node[i], label_node[j]

        parent_node = [-1] * node_count
        parent_edge = [-1] * node_count
        queue = deque([start])
        parent_node[start] = start
        while queue and parent_node[target] == -1:
            node = queue.popleft()
            for edge_index, (u, v, _) in enumerate(edges):
                if u == node:
                    neighbor = v
                elif v == node:
                    neighbor = u
                else:
                    continue
                if parent_node[neighbor] != -1:
                    continue
                parent_node[neighbor] = node
                parent_edge[neighbor] = edge_index
                queue.append(neighbor)
        if parent_node[target] == -1:
            return None

        reverse_nodes = [target]
        reverse_edges: list[int] = []
        while reverse_nodes[-1] != start:
            child = reverse_nodes[-1]
            reverse_edges.append(parent_edge[child])
            reverse_nodes.append(parent_node[child])
        path_nodes = list(reversed(reverse_nodes))
        path_edges = list(reversed(reverse_edges))

        elapsed = 0
        attach_node = None
        split = None
        for offset, path_node in enumerate(path_nodes):
            if attach_distance == elapsed:
                attach_node = path_node
                break
            if offset == len(path_edges):
                break
            edge_index = path_edges[offset]
            weight = edges[edge_index][2]
            next_node = path_nodes[offset + 1]
            if elapsed < attach_distance < elapsed + weight:
                split = (edge_index, path_node, next_node, attach_distance - elapsed)
                break
            elapsed += weight
        if attach_node is None and split is None:
            return None

        if split is not None:
            edge_index, path_node, next_node, first_length = split
            old_weight = edges[edge_index][2]
            internal = node_count
            if internal >= len(label_mask):
                return None
            node_count += 1
            label_mask[internal] = 0
            edges[edge_index] = [path_node, internal, first_length]
            edges.append([internal, next_node, old_weight - first_length])
            attach_node = internal

        assert attach_node is not None
        if limb2 == 0:
            if label_mask[attach_node] != 0:
                return None
            label_node[leaf] = attach_node
            label_mask[attach_node] |= 1 << leaf
        else:
            new_leaf = node_count
            if new_leaf >= len(label_mask):
                return None
            node_count += 1
            label_node[leaf] = new_leaf
            label_mask[new_leaf] = 1 << leaf
            edges.append([attach_node, new_leaf, limb2])
        if len(edges) > MAX_EDGES:
            return None

    for i in range(n):
        for j in range(i + 1, n):
            actual = _tree_distance(node_count, edges, label_node[i], label_node[j])
            if actual != 2 * matrix[i][j]:
                return None

    full_mask = (1 << n) - 1
    records = []
    for edge_index, (u, v, weight) in enumerate(edges):
        seen = {u}
        queue = deque([u])
        mask = label_mask[u]
        while queue:
            node = queue.popleft()
            for other_index, (a, b, _) in enumerate(edges):
                if other_index == edge_index:
                    continue
                if a == node:
                    neighbor = b
                elif b == node:
                    neighbor = a
                else:
                    continue
                if neighbor not in seen:
                    seen.add(neighbor)
                    mask |= label_mask[neighbor]
                    queue.append(neighbor)
        if not (mask & 1):
            mask = full_mask ^ mask
        records.append((mask, weight))
    records.sort()
    return records


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or capacity is not None and (type(capacity) is not int or capacity < 0)
            or input_length is not None and (type(input_length) is not int
                                             or not 0 <= input_length <= MAX_INPUT_LENGTH)
            or input_is_null and values not in (None, [], ())
            or not input_is_null and values is not None and input_length is not None
            and input_length != len(values)):
        return INVALID_RESULT, b""
    if input_is_null or values is None:
        return INVALID_RESULT, b""
    matrix = _decode(values)
    if matrix is None:
        return INVALID_RESULT, b""
    records = _reconstruct(matrix)
    if records is None:
        return 0, b""  # A well-formed but non-additive matrix has null output.
    output_values = [len(records)]
    for mask, weight2 in records:
        output_values.extend((mask, weight2))
    payload = struct.pack("<" + "q" * len(output_values), *output_values)
    if output_is_null or capacity is not None and capacity < len(payload):
        return OUTPUT_ERROR, b""
    return len(payload), payload
