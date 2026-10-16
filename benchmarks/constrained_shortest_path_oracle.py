"""Bounded oracle for the pinned resource-indexed shortest-path DP."""

from __future__ import annotations

INVALID_RESULT = -2
UNREACHABLE_RESULT = -1
MAX_EDGE_COUNT = 64
MAX_INPUT_LENGTH = 5 + 4 * MAX_EDGE_COUNT


def expected_result(values: tuple[int, ...] | list[int]) -> int:
    if (not isinstance(values, (tuple, list)) or not 5 <= len(values) <= MAX_INPUT_LENGTH
            or any(type(value) is not int or not -(2**63) <= value < 2**63 for value in values)):
        return INVALID_RESULT

    node_count, edge_count, start, target, resource_limit = values[:5]
    if (not 1 <= node_count <= 16 or not 0 <= edge_count <= MAX_EDGE_COUNT
            or not 0 <= resource_limit <= 32 or len(values) != 5 + 4 * edge_count
            or not 0 <= start < node_count or not 0 <= target < node_count):
        return INVALID_RESULT

    edges: list[tuple[int, int, int, int]] = []
    for offset in range(5, len(values), 4):
        source, destination, cost, resource = values[offset : offset + 4]
        if (not 0 <= source < node_count or not 0 <= destination < node_count
                or not 0 <= cost <= 1000 or not 1 <= resource <= 32):
            return INVALID_RESULT
        edges.append((source, destination, cost, resource))

    dp: list[list[int | None]] = [
        [None] * node_count for _ in range(resource_limit + 1)
    ]
    dp[0][start] = 0
    for used_resource in range(resource_limit + 1):
        for node in range(node_count):
            current = dp[used_resource][node]
            if current is None:
                continue
            for source, destination, cost, resource in edges:
                if source != node or used_resource + resource > resource_limit:
                    continue
                next_resource = used_resource + resource
                candidate = current + cost
                previous = dp[next_resource][destination]
                if previous is None or candidate < previous:
                    dp[next_resource][destination] = candidate

    answers = [dp[resource][target] for resource in range(resource_limit + 1)]
    reachable = [answer for answer in answers if answer is not None]
    return min(reachable) if reachable else UNREACHABLE_RESULT
