"""Reference contract for the bounded XOR leaf-peeling tree traversal."""

from collections import deque


def expected_output(values, capacity=None, output_is_null=False, input_is_null=False, input_length=None):
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or capacity is not None and (type(capacity) is not int or capacity < 0)
            or input_length is not None and (type(input_length) is not int or input_length < 0)):
        return -1, b""
    if input_is_null or not isinstance(values, (tuple, list)) or len(values) < 2:
        return -1, b""
    if input_length is not None and input_length != len(values):
        return -1, b""
    if any(type(value) is not int or not -(1 << 63) <= value < (1 << 63) for value in values):
        return -1, b""
    n, root = values[:2]
    if not 1 <= n <= 64 or not 0 <= root < n or len(values) != 2 * n:
        return -1, b""
    adjacency = [[] for _ in range(n)]
    edges = set()
    for edge in range(n - 1):
        u, v = values[2 + 2 * edge:4 + 2 * edge]
        if not 0 <= u < n or not 0 <= v < n or u == v:
            return -1, b""
        pair = (min(u, v), max(u, v))
        if pair in edges:
            return -1, b""
        edges.add(pair)
        adjacency[u].append((v, edge))
        adjacency[v].append((u, edge))
    parent = [-1] * n
    parent_vertex = [-1] * n
    parent_vertex[root] = root
    queue = deque([root])
    while queue:
        vertex = queue.popleft()
        for neighbor, edge in adjacency[vertex]:
            if parent_vertex[neighbor] == -1:
                parent_vertex[neighbor] = vertex
                parent[neighbor] = edge
                queue.append(neighbor)
    if any(vertex == -1 for vertex in parent_vertex):
        return -1, b""
    child_count = [0] * n
    for vertex in range(n):
        if vertex != root:
            child_count[parent_vertex[vertex]] += 1
    order = []
    for start in range(n):
        vertex = start
        while vertex != root and child_count[vertex] == 0:
            child_count[vertex] = -1
            order.append(vertex)
            vertex = parent_vertex[vertex]
            child_count[vertex] -= 1
    order.append(root)
    data = b"".join(value.to_bytes(8, "little", signed=True) for value in parent + order)
    if output_is_null or (capacity is not None and capacity < len(data)):
        return -2, b""
    return len(data), data
