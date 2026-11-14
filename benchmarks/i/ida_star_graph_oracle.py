"""Independent breadth-first reference for the bounded IDA* graph profile."""

from collections import deque

INVALID = -(1 << 63)
MAX_VALID_INPUT_LENGTH = 112
MAX_PARSEABLE_INPUT_LENGTH = 113


def expected_result(values):
    if not isinstance(values, (list, tuple)) or len(values) < 5:
        return INVALID
    if any(type(value) is not int or value < INVALID or value >= (1 << 63) for value in values):
        return INVALID
    n, m, start, goal = values[:4]
    if not (1 <= n <= 12 and 0 <= m <= 48 and 0 <= start < n and 0 <= goal < n):
        return INVALID
    if len(values) != 4 + n + 2 * m:
        return INVALID
    heuristic = values[4:4+n]
    if any(not 0 <= value < n for value in heuristic) or heuristic[goal] != 0:
        return INVALID
    edges = [set() for _ in range(n)]
    for index in range(m):
        u, v = values[4+n+2*index:6+n+2*index]
        if (not 0 <= u < n or not 0 <= v < n or u == v or v in edges[u]
                or heuristic[u] > heuristic[v] + 1):
            return INVALID
        edges[u].add(v)
    distance = [-1] * n
    distance[start] = 0
    queue = deque([start])
    while queue:
        u = queue.popleft()
        for v in edges[u]:
            if distance[v] < 0:
                distance[v] = distance[u] + 1
                queue.append(v)
    return distance[goal]
