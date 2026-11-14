"""Bounded directed girth using one breadth-first search per start."""

from collections import deque


def expected_output(values, input_is_null=False, input_length=None):
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (tuple, list)) or not 2 <= len(values) <= 131
            or input_length is not None and (type(input_length) is not int or input_length != len(values))
            or any(type(x) is not int or not -(1 << 63) <= x < (1 << 63) for x in values)):
        return -1
    n, m = values[:2]
    if not 1 <= n <= 16 or not 0 <= m <= 64 or len(values) != 2 + 2 * m:
        return -1
    outgoing = [[] for _ in range(n)]
    for i in range(m):
        u, v = values[2 + 2*i:4 + 2*i]
        if not 0 <= u < n or not 0 <= v < n:
            return -1
        outgoing[u].append(v)
    best = n + 1
    for start in range(n):
        distance = [-1] * n
        distance[start] = 0
        queue = deque([start])
        while queue:
            u = queue.popleft()
            for v in outgoing[u]:
                if v == start:
                    best = min(best, distance[u] + 1)
                elif distance[v] < 0:
                    distance[v] = distance[u] + 1
                    queue.append(v)
    return 0 if best == n + 1 else best
