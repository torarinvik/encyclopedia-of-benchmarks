"""Independent adjacency-map oracle for additive distance-matrix trees."""

from __future__ import annotations

import struct
from collections import deque
from collections.abc import Sequence

MAX_N = 6
MAX_INPUT_LENGTH = 1 + MAX_N * MAX_N + 1
MAX_OUTPUT_BYTES = 152


def _read_matrix(values: Sequence[int] | None) -> list[list[int]] | None:
    if (not isinstance(values, (list, tuple)) or not 1 <= len(values) <= MAX_INPUT_LENGTH
            or any(type(x) is not int or not -(1 << 63) <= x < (1 << 63) for x in values)):
        return None
    n = values[0]
    if not 2 <= n <= MAX_N or len(values) != 1 + n * n:
        return None
    d = [[values[1 + i * n + j] for j in range(n)] for i in range(n)]
    for i in range(n):
        for j in range(n):
            if (i == j and d[i][j] != 0) or (i != j and not 1 <= d[i][j] <= 32):
                return None
            if d[i][j] != d[j][i]:
                return None
    return d


def _build(d: list[list[int]]) -> list[tuple[int, int]] | None:
    n = len(d)
    graph: dict[int, dict[int, int]] = {0: {1: 2 * d[0][1]}, 1: {0: 2 * d[0][1]}}
    labels = [0, 1]
    next_vertex = 2

    def insert_leaf(k: int) -> bool:
        nonlocal next_vertex
        if k == 2:
            return True
        if not insert_leaf(k - 1):
            return False
        leaf = k - 1
        limb2 = min(d[a][leaf] + d[b][leaf] - d[a][b]
                    for a in range(leaf) for b in range(a + 1, leaf))
        if limb2 < 0:
            return False
        witness = None
        for a in range(leaf):
            for b in range(a + 1, leaf):
                from_a = 2 * d[a][leaf] - limb2
                from_b = 2 * d[b][leaf] - limb2
                if from_a >= 0 and from_b >= 0 and 2 * d[a][b] == from_a + from_b:
                    witness = (a, b, from_a)
                    break
            if witness is not None:
                break
        if witness is None:
            return False
        a, b, attach_distance = witness
        start, goal = labels[a], labels[b]
        parent: dict[int, tuple[int, int] | None] = {start: None}
        queue = deque([start])
        while queue and goal not in parent:
            node = queue.popleft()
            for neighbor, weight in sorted(graph[node].items()):
                if neighbor not in parent:
                    parent[neighbor] = (node, weight)
                    queue.append(neighbor)
        if goal not in parent:
            return False
        reverse_nodes = [goal]
        reverse_weights = []
        current = goal
        while current != start:
            previous, weight = parent[current]  # type: ignore[misc]
            reverse_weights.append(weight)
            reverse_nodes.append(previous)
            current = previous
        nodes = list(reversed(reverse_nodes))
        weights = list(reversed(reverse_weights))

        distance = 0
        attach_at = None
        split_at = None
        for step, node in enumerate(nodes):
            if distance == attach_distance:
                attach_at = node
                break
            if step == len(weights):
                break
            weight = weights[step]
            if distance < attach_distance < distance + weight:
                split_at = (node, nodes[step + 1], attach_distance - distance, weight)
                break
            distance += weight
        if attach_at is None and split_at is None:
            return False
        if split_at is not None:
            left, right, first, whole = split_at
            del graph[left][right]
            del graph[right][left]
            attach_at = next_vertex
            next_vertex += 1
            graph[attach_at] = {left: first, right: whole - first}
            graph[left][attach_at] = first
            graph[right][attach_at] = whole - first

        if limb2 == 0:
            if labels.count(attach_at) > 0:
                return False
            labels.append(attach_at)
        else:
            new_leaf = next_vertex
            next_vertex += 1
            graph[new_leaf] = {attach_at: limb2}
            graph[attach_at][new_leaf] = limb2
            labels.append(new_leaf)
        return True

    if not insert_leaf(n):
        return None

    for i in range(n):
        for j in range(i + 1, n):
            todo = [(labels[i], -1, 0)]
            seen = {labels[i]}
            actual = None
            while todo:
                node, previous, distance = todo.pop()
                if node == labels[j]:
                    actual = distance
                    break
                for neighbor, weight in graph[node].items():
                    if neighbor != previous and neighbor not in seen:
                        seen.add(neighbor)
                        todo.append((neighbor, node, distance + weight))
            if actual != 2 * d[i][j]:
                return None

    full = (1 << n) - 1
    records = []
    edge_pairs = [(u, v) for u in graph for v in graph[u] if u < v]
    for u, v in edge_pairs:
        seen = {u}
        todo = [u]
        mask = 0
        while todo:
            node = todo.pop()
            for label, vertex in enumerate(labels):
                if vertex == node:
                    mask |= 1 << label
            for neighbor in graph[node]:
                if (node == u and neighbor == v) or (node == v and neighbor == u):
                    continue
                if neighbor not in seen:
                    seen.add(neighbor)
                    todo.append(neighbor)
        if not (mask & 1):
            mask = full ^ mask
        records.append((mask, graph[u][v]))
    records.sort()
    return records


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    invalid, output_error = -1, -2
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or capacity is not None and (type(capacity) is not int or capacity < 0)
            or input_length is not None and (type(input_length) is not int
                                             or not 0 <= input_length <= MAX_INPUT_LENGTH)
            or input_is_null and values not in (None, [], ())
            or not input_is_null and values is not None and input_length is not None
            and input_length != len(values)):
        return invalid, b""
    if input_is_null or values is None:
        return invalid, b""
    d = _read_matrix(values)
    if d is None:
        return invalid, b""
    records = _build(d)
    if records is None:
        return 0, b""
    payload_values = [len(records)]
    for mask, length2 in records:
        payload_values.extend((mask, length2))
    payload = struct.pack("<" + "q" * len(payload_values), *payload_values)
    if output_is_null or capacity is not None and capacity < len(payload):
        return output_error, b""
    return len(payload), payload
