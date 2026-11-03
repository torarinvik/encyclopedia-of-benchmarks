"""Independent Edmonds–Karp oracle for the bounded Dinic benchmark."""
from collections import deque


def expected_result(values):
    if not isinstance(values, (list, tuple)) or len(values) < 4:
        return -1
    if any(type(value) is not int for value in values):
        return -1
    n, m, source, sink = values[:4]
    if not (2 <= n <= 16 and 0 <= m <= 64 and 1 <= source <= n
            and 1 <= sink <= n and source != sink and len(values) == 4 + 3 * m):
        return -1
    residual = [[0] * n for _ in range(n)]
    for i in range(m):
        u, v, capacity = values[4 + 3 * i:7 + 3 * i]
        if not (1 <= u <= n and 1 <= v <= n and u != v and 0 <= capacity <= 100):
            return -1
        residual[u - 1][v - 1] += capacity
    source -= 1
    sink -= 1
    flow = 0
    while True:
        parent = [-1] * n
        parent[source] = source
        queue = deque([source])
        while queue and parent[sink] < 0:
            u = queue.popleft()
            for v in range(n):
                if parent[v] < 0 and residual[u][v] > 0:
                    parent[v] = u
                    queue.append(v)
        if parent[sink] < 0:
            return flow
        amount = 6401
        v = sink
        while v != source:
            u = parent[v]
            amount = min(amount, residual[u][v])
            v = u
        v = sink
        while v != source:
            u = parent[v]
            residual[u][v] -= amount
            residual[v][u] += amount
            v = u
        flow += amount
