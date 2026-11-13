"""Primary bounded ISAP maximum-flow oracle."""

MAX_VERTICES = 8
MAX_EDGES = 24
MAX_CAPACITY = 100
MAX_VALID_INPUT_LENGTH = 4 + 3 * MAX_EDGES
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_INPUT_LENGTH = MAX_PARSEABLE_INPUT_LENGTH
MAX_FLOW = MAX_EDGES * MAX_CAPACITY


def _parse(values):
    if (not isinstance(values, (list, tuple))
            or len(values) < 4 or len(values) > MAX_PARSEABLE_INPUT_LENGTH
            or any(type(value) is not int for value in values)):
        return None
    n, edge_count, source, sink = values[:4]
    if (not 2 <= n <= MAX_VERTICES or not 0 <= edge_count <= MAX_EDGES
            or not 0 <= source < n or not 0 <= sink < n or source == sink
            or len(values) != 4 + 3 * edge_count):
        return None
    edges = []
    for index in range(edge_count):
        u, v, capacity = values[4 + 3 * index:7 + 3 * index]
        if (not 0 <= u < n or not 0 <= v < n or u == v
                or not 0 <= capacity <= MAX_CAPACITY):
            return None
        edges.append((u, v, capacity))
    return n, source, sink, edges


def _isap(n, source, sink, edges):
    residual = [[0] * n for _ in range(n)]
    for u, v, capacity in edges:
        residual[u][v] += capacity

    distance = [n] * n
    distance[sink] = 0
    queue = [sink]
    head = 0
    while head < len(queue):
        vertex = queue[head]
        head += 1
        for predecessor in range(n):
            if distance[predecessor] == n and residual[predecessor][vertex] > 0:
                distance[predecessor] = distance[vertex] + 1
                queue.append(predecessor)
    if distance[source] >= n:
        return 0

    gap = [0] * (n + 1)
    for label in distance:
        gap[label] += 1
    current = [0] * n
    terminated = False

    def send(vertex, amount):
        nonlocal terminated
        if vertex == sink or amount == 0 or terminated:
            return amount if vertex == sink else 0
        while current[vertex] < n:
            neighbor = current[vertex]
            if (residual[vertex][neighbor] > 0
                    and distance[vertex] == distance[neighbor] + 1):
                pushed = send(neighbor, min(amount, residual[vertex][neighbor]))
                if pushed > 0:
                    residual[vertex][neighbor] -= pushed
                    residual[neighbor][vertex] += pushed
                    return pushed
                if terminated:
                    return 0
            current[vertex] += 1

        old = distance[vertex]
        best_neighbor = n
        for neighbor in range(n):
            if residual[vertex][neighbor] > 0 and distance[neighbor] < best_neighbor:
                best_neighbor = distance[neighbor]
        new = min(n, best_neighbor + 1)
        gap[old] -= 1
        distance[vertex] = new
        gap[new] += 1
        current[vertex] = 0
        if old < n and gap[old] == 0:
            terminated = True
        return 0

    total = 0
    while distance[source] < n and not terminated:
        pushed = send(source, MAX_FLOW)
        if pushed > 0:
            total += pushed
    return total


def expected_result(values):
    """Return maximum flow, or -1 for a malformed packed graph."""
    parsed = _parse(values)
    if parsed is None:
        return -1
    return _isap(*parsed)
