"""Unexecuted highest-label push-relabel reference with dense residuals."""


def expected_output(values, input_is_null=False, input_length=None):
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (tuple, list)) or not 4 <= len(values) <= 197
            or input_length is not None and (type(input_length) is not int or input_length != len(values))
            or any(type(x) is not int or not -(1 << 63) <= x < (1 << 63) for x in values)):
        return -1
    n, m, source, sink = values[:4]
    if not (2 <= n <= 16 and 0 <= m <= 64 and 1 <= source <= n
            and 1 <= sink <= n and source != sink and len(values) == 4+3*m):
        return -1
    residual = [[0]*n for _ in range(n)]
    for i in range(m):
        u, v, capacity = values[4+3*i:7+3*i]
        if not (1 <= u <= n and 1 <= v <= n and u != v and 0 <= capacity <= 100):
            return -1
        residual[u-1][v-1] += capacity
    source -= 1
    sink -= 1
    height = [0]*n
    excess = [0]*n
    height[source] = n
    for v in range(n):
        amount = residual[source][v]
        residual[source][v] = 0
        residual[v][source] += amount
        excess[v] += amount
        excess[source] -= amount
    while True:
        active = [v for v in range(n) if v != source and v != sink and excess[v] > 0]
        if not active:
            return excess[sink]
        u = min(active, key=lambda v: (-height[v], v))
        for v in range(n):
            if residual[u][v] and height[u] == height[v]+1:
                amount = min(excess[u], residual[u][v])
                residual[u][v] -= amount
                residual[v][u] += amount
                excess[u] -= amount
                excess[v] += amount
                break
        else:
            height[u] = 1+min(height[v] for v in range(n) if residual[u][v])
