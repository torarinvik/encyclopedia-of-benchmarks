"""Vertex-split Edmonds–Karp oracle for the bounded vertex-connectivity profile."""

MAX_VERTICES = 10
MAX_EDGES = 45
MAX_INPUT_LENGTH = 92
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1


def _parse(values, input_is_null=False, input_length=None):
    if (not isinstance(values, (list, tuple)) or len(values) > MAX_INPUT_LENGTH
            or type(input_is_null) is not bool or (input_is_null and len(values) != 0)
            or (input_length is not None
                and (type(input_length) is not int or input_length != len(values)))
            or any(type(value) is not int or not I64_MIN <= value <= I64_MAX
                   for value in values)):
        return None
    if input_is_null or len(values) < 2:
        return None
    n, m = values[:2]
    if not (0 <= n <= MAX_VERTICES and 0 <= m <= MAX_EDGES):
        return None
    if len(values) != 2 + 2*m:
        return None
    adjacency = [0] * n
    for pos in range(2, len(values), 2):
        left, right = values[pos], values[pos + 1]
        if not (0 <= left < n and 0 <= right < n):
            return None
        if left != right:
            adjacency[left] |= 1 << right
            adjacency[right] |= 1 << left
    return n, adjacency


def _connected(adjacency):
    n = len(adjacency)
    if n <= 1:
        return True
    visited = 1
    queue = [0]
    for vertex in queue:
        unseen = adjacency[vertex] & ~visited
        while unseen:
            bit = unseen & -unseen
            unseen -= bit
            visited |= bit
            queue.append(bit.bit_length() - 1)
    return visited == (1 << n) - 1


def _pair_vertex_flow(adjacency, source_vertex, target_vertex, limit):
    n = len(adjacency)
    node_count = 2 * n
    residual = [[0] * node_count for _ in range(node_count)]
    for vertex in range(n):
        residual[2 * vertex][2 * vertex + 1] = (
            n if vertex in (source_vertex, target_vertex) else 1
        )
    for left in range(n):
        for right in range(left + 1, n):
            if adjacency[left] & (1 << right):
                residual[2 * left + 1][2 * right] = 1
                residual[2 * right + 1][2 * left] = 1

    source = 2 * source_vertex + 1
    sink = 2 * target_vertex
    flow = 0
    while flow < limit:
        parent = [-1] * node_count
        parent[source] = source
        queue = [source]
        for vertex in queue:
            if parent[sink] >= 0:
                break
            for neighbor in range(node_count):
                if parent[neighbor] < 0 and residual[vertex][neighbor] > 0:
                    parent[neighbor] = vertex
                    queue.append(neighbor)
                    if neighbor == sink:
                        break
        if parent[sink] < 0:
            break
        amount = limit - flow
        vertex = sink
        while vertex != source:
            previous = parent[vertex]
            amount = min(amount, residual[previous][vertex])
            vertex = previous
        vertex = sink
        while vertex != source:
            previous = parent[vertex]
            residual[previous][vertex] -= amount
            residual[vertex][previous] += amount
            vertex = previous
        flow += amount
    return flow


def expected_result(values, input_is_null=False, input_length=None):
    graph = _parse(values, input_is_null, input_length)
    if graph is None:
        return -1
    n, adjacency = graph
    if n <= 1:
        return 0
    if not _connected(adjacency):
        return 0
    best = n - 1
    for source in range(n):
        for target in range(source + 1, n):
            if adjacency[source] & (1 << target):
                continue
            best = min(best, _pair_vertex_flow(adjacency, source, target, best))
            if best == 0:
                return 0
    return best
