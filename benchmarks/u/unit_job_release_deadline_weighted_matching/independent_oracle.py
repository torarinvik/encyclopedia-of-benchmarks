"""Unexecuted min-cost-flow reference for weighted unit-job scheduling."""


def expected_output(values, input_is_null=False, input_length=None):
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple)) or not 1 <= len(values) <= 98
            or input_length is not None and (type(input_length) is not int or input_length != len(values))
            or any(type(v) is not int or not -(1 << 63) <= v < (1 << 63) for v in values)):
        return -1
    n = values[0]
    if not 0 <= n <= 32 or len(values) != 1 + 3*n:
        return -1
    jobs = []
    for i in range(n):
        r, d, w = values[1+3*i:4+3*i]
        if not 0 <= r <= d < 32 or not 0 <= w <= 1_000_000:
            return -1
        jobs.append((r, d, w))

    source, sink = n + 32, n + 33
    graph = [[] for _ in range(n + 34)]

    def edge(u, v, cost):
        graph[u].append([v, 1, cost, len(graph[v])])
        graph[v].append([u, 0, -cost, len(graph[u]) - 1])

    for job, (r, d, w) in enumerate(jobs):
        edge(source, job, -w)
        for slot in range(r, d+1):
            edge(job, n+slot, 0)
    for slot in range(32):
        edge(n+slot, sink, 0)

    cost = 0
    while True:
        dist = [None] * len(graph)
        previous = [None] * len(graph)
        dist[source] = 0
        for _ in range(len(graph)-1):
            changed = False
            for u, edges in enumerate(graph):
                if dist[u] is None:
                    continue
                for index, (v, capacity, price, _) in enumerate(edges):
                    if capacity and (dist[v] is None or dist[u] + price < dist[v]):
                        dist[v] = dist[u] + price
                        previous[v] = (u, index)
                        changed = True
            if not changed:
                break
        if dist[sink] is None or dist[sink] >= 0:
            break
        cost += dist[sink]
        node = sink
        while node != source:
            u, index = previous[node]
            arc = graph[u][index]
            arc[1] -= 1
            graph[node][arc[3]][1] += 1
            node = u
    return -cost
