"""Independent direct-path oracle for vertex-set affine composition."""

from collections import deque
import struct

MOD = 998244353
MAX_N = 64
MAX_Q = 64
MAX_PARSEABLE_INPUT_LENGTH = 4 * MAX_N + 4 * MAX_Q
MAX_OUTPUT_BYTES = 8 * MAX_Q


def expected_output(values, capacity=None, output_is_null=False,
                    input_is_null=False, input_length=None):
    """Return ``(result, bytes)`` for the bounded packed tree trace."""
    if input_is_null or not isinstance(values, (list, tuple)):
        return -1, b""
    if input_length is None:
        input_length = len(values)
    if (type(input_length) is not int
            or input_length > MAX_PARSEABLE_INPUT_LENGTH
            or input_length != len(values)
            or len(values) < 2):
        return -1, b""
    if any(type(value) is not int for value in values):
        return -1, b""

    n, q = values[:2]
    if not 1 <= n <= MAX_N or not 1 <= q <= MAX_Q:
        return -1, b""
    if len(values) != 4 * n + 4 * q:
        return -1, b""

    functions = []
    for offset in range(2, 2 + 2 * n, 2):
        a, b = values[offset:offset + 2]
        if not 1 <= a < MOD or not 0 <= b < MOD:
            return -1, b""
        functions.append([a, b])

    graph = [[] for _ in range(n)]
    dsu = list(range(n))
    sizes = [1] * n

    def find(item):
        while dsu[item] != item:
            dsu[item] = dsu[dsu[item]]
            item = dsu[item]
        return item

    edge_start = 2 + 2 * n
    for offset in range(edge_start, edge_start + 2 * (n - 1), 2):
        left, right = values[offset:offset + 2]
        if not 0 <= left < n or not 0 <= right < n or left == right:
            return -1, b""
        root_left, root_right = find(left), find(right)
        if root_left == root_right:
            return -1, b""
        if sizes[root_left] < sizes[root_right]:
            root_left, root_right = root_right, root_left
        dsu[root_right] = root_left
        sizes[root_left] += sizes[root_right]
        graph[left].append(right)
        graph[right].append(left)

    operation_start = edge_start + 2 * (n - 1)
    operations = []
    query_count = 0
    for query in range(q):
        offset = operation_start + 4 * query
        kind, first, second, third = values[offset:offset + 4]
        if kind == 0:
            if not 0 <= first < n or not 1 <= second < MOD or not 0 <= third < MOD:
                return -1, b""
        elif kind == 1:
            if not 0 <= first < n or not 0 <= second < n or not 0 <= third < MOD:
                return -1, b""
            query_count += 1
        else:
            return -1, b""
        operations.append((kind, first, second, third))

    answers = []
    for kind, first, second, third in operations:
        if kind == 0:
            functions[first] = [second, third]
            continue
        start, target, value = first, second, third
        parent = [-1] * n
        parent[start] = start
        pending = deque([start])
        while pending and parent[target] == -1:
            vertex = pending.popleft()
            for neighbor in graph[vertex]:
                if parent[neighbor] == -1:
                    parent[neighbor] = vertex
                    pending.append(neighbor)
        reverse_path = []
        current = target
        while current != start:
            reverse_path.append(current)
            current = parent[current]
        reverse_path.append(start)
        for vertex in reversed(reverse_path):
            a, b = functions[vertex]
            value = (a * value + b) % MOD
        answers.append(value)

    required = 8 * query_count
    effective_capacity = MAX_OUTPUT_BYTES if capacity is None else capacity
    if (type(output_is_null) is not bool
            or type(effective_capacity) is not int
            or effective_capacity < 0):
        return -2, b""
    if output_is_null or effective_capacity < required:
        return -2, b""
    output = b"".join(struct.pack("<q", answer) for answer in answers)
    return len(output), output
