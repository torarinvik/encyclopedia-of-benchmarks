"""Unexecuted thresholded level-graph maximum-flow reference."""

from collections import deque


def expected_output(values, input_is_null=False, input_length=None):
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple)) or not 4 <= len(values) <= 197
            or input_length is not None and (type(input_length) is not int or input_length != len(values))
            or any(type(x) is not int or not -(1 << 63) <= x < (1 << 63) for x in values)):
        return -1
    n, m, source, sink = values[:4]
    if not (2 <= n <= 16 and 0 <= m <= 64 and 1 <= source <= n
            and 1 <= sink <= n and source != sink and len(values) == 4 + 3*m):
        return -1
    residual = [[0] * n for _ in range(n)]
    for i in range(m):
        u, v, capacity = values[4+3*i:7+3*i]
        if not (1 <= u <= n and 1 <= v <= n and u != v and 0 <= capacity <= 100):
            return -1
        residual[u-1][v-1] += capacity
    source -= 1
    sink -= 1
    greatest = max(max(row) for row in residual)
    threshold = 1 << (greatest.bit_length()-1) if greatest else 0
    flow = 0
    while threshold:
        while True:
            level = [-1] * n
            level[source] = 0
            queue = deque([source])
            while queue:
                u = queue.popleft()
                for v in range(n):
                    if level[v] < 0 and residual[u][v] >= threshold:
                        level[v] = level[u]+1
                        queue.append(v)
            if level[sink] < 0:
                break
            next_vertex = [0] * n

            def send(u, amount):
                if u == sink:
                    return amount
                while next_vertex[u] < n:
                    v = next_vertex[u]
                    if level[v] == level[u]+1 and residual[u][v] >= threshold:
                        pushed = send(v, min(amount, residual[u][v]))
                        if pushed:
                            residual[u][v] -= pushed
                            residual[v][u] += pushed
                            return pushed
                    next_vertex[u] += 1
                return 0

            while True:
                pushed = send(source, 6401)
                if not pushed:
                    break
                flow += pushed
        threshold //= 2
    return flow
