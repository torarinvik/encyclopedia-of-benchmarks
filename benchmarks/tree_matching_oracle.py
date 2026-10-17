"""Independent reference for the bounded weighted tree matching workload."""

from __future__ import annotations

MAX_NODES = 64
MAX_WEIGHT = 1000
MAX_VALID_INPUT_LENGTH = 2 + 3 * (MAX_NODES - 1)
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH
MAX_INPUT_LENGTH = MAX_PARSEABLE_INPUT_LENGTH
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1
INVALID_RESULT = -1


def expected_result(values: list[int]) -> int:
    if (
        not isinstance(values, (list, tuple))
        or not 2 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
        or any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values)
    ):
        return INVALID_RESULT
    count, root = values[0], values[1]
    if not 1 <= count <= MAX_NODES or not 0 <= root < count:
        return INVALID_RESULT
    if len(values) != 2 + 3 * (count - 1):
        return INVALID_RESULT

    graph: list[list[tuple[int, int]]] = [[] for _ in range(count)]
    edges: set[tuple[int, int]] = set()
    for index in range(2, len(values), 3):
        left, right, weight = values[index : index + 3]
        if not (0 <= left < count and 0 <= right < count) or left == right:
            return INVALID_RESULT
        if not 0 <= weight <= MAX_WEIGHT:
            return INVALID_RESULT
        edge = (min(left, right), max(left, right))
        if edge in edges:
            return INVALID_RESULT
        edges.add(edge)
        graph[left].append((right, weight))
        graph[right].append((left, weight))

    # Build a rooted order first; a repeated non-parent vertex signals a cycle.
    parent = [-2] * count
    parent[root] = -1
    order = [root]
    for node in order:
        for neighbor, _weight in graph[node]:
            if neighbor == parent[node]:
                continue
            if parent[neighbor] != -2:
                return INVALID_RESULT
            parent[neighbor] = node
            order.append(neighbor)
    if len(order) != count:
        return INVALID_RESULT

    without_child_edge = [0] * count
    with_child_edge = [0] * count
    for node in reversed(order):
        best_without = 0
        for child, weight in graph[node]:
            if parent[child] != node:
                continue
            child_best = max(without_child_edge[child], with_child_edge[child])
            best_without += child_best
        # Evaluate choosing each individual child edge against the same base sum.
        best_with = 0
        for child, weight in graph[node]:
            if parent[child] == node:
                child_best = max(without_child_edge[child], with_child_edge[child])
                best_with = max(
                    best_with,
                    best_without - child_best + without_child_edge[child] + weight,
                )
        without_child_edge[node] = best_without
        with_child_edge[node] = best_with

    return max(without_child_edge[root], with_child_edge[root])
