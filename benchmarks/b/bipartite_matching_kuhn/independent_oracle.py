"""Maximum bipartite matching by unit-capacity flow and breadth-first paths."""

from collections import deque


def expected_output(values):
    if (not isinstance(values, (list, tuple)) or len(values) < 3
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63) for value in values)):
        return -1
    left, right, edges = values[:3]
    if not 0 <= left <= 64 or not 0 <= right <= 64 or not 0 <= edges <= 4096 or len(values) != 3 + 2 * edges:
        return -1
    source = left + right
    sink = source + 1
    size = sink + 1
    capacity = [[0] * size for _ in range(size)]
    for u in range(left):
        capacity[source][u] = 1
    for v in range(right):
        capacity[left + v][sink] = 1
    for offset in range(3, len(values), 2):
        u, v = values[offset:offset + 2]
        if not 0 <= u < left or not 0 <= v < right:
            return -1
        capacity[u][left + v] = 1
    flow = 0
    while True:
        parent = [-1] * size
        parent[source] = source
        queue = deque([source])
        while queue and parent[sink] < 0:
            node = queue.popleft()
            for other in range(size):
                if capacity[node][other] and parent[other] < 0:
                    parent[other] = node
                    queue.append(other)
        if parent[sink] < 0:
            return flow
        node = sink
        while node != source:
            prev = parent[node]
            capacity[prev][node] -= 1
            capacity[node][prev] += 1
            node = prev
        flow += 1
