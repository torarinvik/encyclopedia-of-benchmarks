"""Independent weighted-tree diameter path oracle."""

from collections import deque
import struct

MAX_N = 64
MAX_PARSEABLE_INPUT_LENGTH = 1 + 3 * (MAX_N - 1)
MAX_OUTPUT_BYTES = 8 * (2 + MAX_N)
MAX_EDGE_WEIGHT = 1_000_000_000


def _traverse(graph, start):
    distance = [None] * len(graph)
    parent = [-1] * len(graph)
    distance[start] = 0
    pending = deque([start])
    while pending:
        vertex = pending.popleft()
        for neighbor, weight in graph[vertex]:
            if distance[neighbor] is None:
                distance[neighbor] = distance[vertex] + weight
                parent[neighbor] = vertex
                pending.append(neighbor)
    farthest = min(vertex for vertex, value in enumerate(distance)
                   if value == max(distance))
    return distance, parent, farthest


def expected_output(values, capacity=None, output_is_null=False,
                    input_is_null=False, input_length=None):
    """Return ``(result, bytes)`` for ``[N,(u,v,w)...]``."""
    if input_is_null or not isinstance(values, (list, tuple)):
        return -1, b""
    if input_length is None:
        input_length = len(values)
    if (type(input_length) is not int
            or input_length > MAX_PARSEABLE_INPUT_LENGTH
            or input_length != len(values)
            or len(values) < 1):
        return -1, b""
    if any(type(value) is not int for value in values):
        return -1, b""
    n = values[0]
    if not 1 <= n <= MAX_N or len(values) != 1 + 3 * (n - 1):
        return -1, b""

    graph = [[] for _ in range(n)]
    dsu = list(range(n))
    sizes = [1] * n

    def find(item):
        while dsu[item] != item:
            dsu[item] = dsu[dsu[item]]
            item = dsu[item]
        return item

    for offset in range(1, len(values), 3):
        left, right, weight = values[offset:offset + 3]
        if (not 0 <= left < n or not 0 <= right < n or left == right
                or not 1 <= weight <= MAX_EDGE_WEIGHT):
            return -1, b""
        root_left, root_right = find(left), find(right)
        if root_left == root_right:
            return -1, b""
        if sizes[root_left] < sizes[root_right]:
            root_left, root_right = root_right, root_left
        dsu[root_right] = root_left
        sizes[root_left] += sizes[root_right]
        graph[left].append((right, weight))
        graph[right].append((left, weight))

    if n == 1:
        output_values = [0, 1, 0]
    else:
        _, _, first_endpoint = _traverse(graph, 0)
        distance, parent, second_endpoint = _traverse(graph, first_endpoint)
        path = []
        current = second_endpoint
        while current != -1:
            path.append(current)
            if current == first_endpoint:
                break
            current = parent[current]
        path.reverse()
        output_values = [distance[second_endpoint], len(path), *path]

    required = 8 * len(output_values)
    effective_capacity = MAX_OUTPUT_BYTES if capacity is None else capacity
    if (type(output_is_null) is not bool
            or type(effective_capacity) is not int
            or effective_capacity < 0):
        return -2, b""
    if output_is_null or effective_capacity < required:
        return -2, b""
    output = b"".join(struct.pack("<q", value) for value in output_values)
    return len(output), output
