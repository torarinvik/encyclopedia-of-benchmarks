"""Bounded degree/XOR simulation for the leaf-peeling traversal."""


def expected_output(values, capacity=None, output_is_null=False, input_is_null=False, input_length=None):
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or capacity is not None and (type(capacity) is not int or capacity < 0)
            or input_length is not None and (type(input_length) is not int or input_length < 0)):
        return -1, b""
    if input_is_null or not isinstance(values, (tuple, list)) or len(values) < 2:
        return -1, b""
    if input_length is not None and input_length != len(values):
        return -1, b""
    if any(type(x) is not int or not -(1 << 63) <= x < (1 << 63) for x in values):
        return -1, b""
    n, root = values[:2]
    if not 1 <= n <= 64 or not 0 <= root < n or len(values) != 2 * n:
        return -1, b""
    degree = [0] * n
    incident = [0] * n
    edges = []
    groups = list(range(n))
    ranks = [0] * n
    for edge in range(n - 1):
        u, v = values[2 + 2 * edge:4 + 2 * edge]
        if not 0 <= u < n or not 0 <= v < n or u == v:
            return -1, b""
        x, y = u, v
        while groups[x] != x:
            groups[x] = groups[groups[x]]
            x = groups[x]
        while groups[y] != y:
            groups[y] = groups[groups[y]]
            y = groups[y]
        if x == y:
            return -1, b""
        if ranks[x] < ranks[y]:
            x, y = y, x
        groups[y] = x
        if ranks[x] == ranks[y]:
            ranks[x] += 1
        edges.append((u, v))
        degree[u] += 1
        degree[v] += 1
        incident[u] ^= edge
        incident[v] ^= edge
    degree[root] = 0
    parents = [-1] * n
    order = []
    for start in range(n):
        v = start
        while degree[v] == 1:
            edge = incident[v]
            u, w = edges[edge]
            neighbor = u ^ w ^ v
            parents[v] = edge
            order.append(v)
            degree[v] = 0
            degree[neighbor] -= 1
            incident[neighbor] ^= edge
            v = neighbor
    order.append(root)
    if len(order) != n:
        return -1, b""
    result = b"".join(x.to_bytes(8, "little", signed=True) for x in parents + order)
    if output_is_null or (capacity is not None and capacity < len(result)):
        return -2, b""
    return len(result), result
