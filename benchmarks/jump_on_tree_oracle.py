"""Independent direct-path oracle for the bounded Jump on Tree profile."""

from collections import deque
import struct

MAX_N = 64
MAX_Q = 64
MAX_PARSEABLE_INPUT_LENGTH = 2 + 2 * (MAX_N - 1) + 3 * MAX_Q
MAX_OUTPUT_BYTES = 8 * MAX_Q


def expected_output(values, capacity=None, output_is_null=False,
                    input_is_null=False, input_length=None):
    """Return ``(result, bytes)`` for ``[N,Q,(u,v)...,(s,t,k)...]``."""
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
    if not 2 <= n <= MAX_N or not 1 <= q <= MAX_Q:
        return -1, b""
    if len(values) != 2 + 2 * (n - 1) + 3 * q:
        return -1, b""

    graph = [[] for _ in range(n)]
    dsu = list(range(n))
    sizes = [1] * n

    def find(item):
        while dsu[item] != item:
            dsu[item] = dsu[dsu[item]]
            item = dsu[item]
        return item

    edge_end = 2 + 2 * (n - 1)
    for offset in range(2, edge_end, 2):
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

    answers = []
    for offset in range(edge_end, len(values), 3):
        start, target, index = values[offset:offset + 3]
        if (not 0 <= start < n or not 0 <= target < n
                or not 0 <= index < n):
            return -1, b""
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
        path = list(reversed(reverse_path))
        answers.append(path[index] if index < len(path) else -1)

    required = 8 * len(answers)
    effective_capacity = MAX_OUTPUT_BYTES if capacity is None else capacity
    if (type(output_is_null) is not bool
            or type(effective_capacity) is not int
            or effective_capacity < 0):
        return -2, b""
    if output_is_null or effective_capacity < required:
        return -2, b""
    output = b"".join(struct.pack("<q", answer) for answer in answers)
    return len(output), output
