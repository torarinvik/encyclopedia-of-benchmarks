"""Independent all-sources BFS oracle for tree-distance frequencies."""

from collections import deque
import struct

MAX_N = 64
MAX_PARSEABLE_INPUT_LENGTH = 1 + 2 * (MAX_N - 1)
MAX_OUTPUT_BYTES = 8 * (MAX_N - 1)


def expected_output(values, capacity=None, output_is_null=False,
                    input_is_null=False, input_length=None):
    """Return ``(result, bytes)`` for ``[N,(u,v)...]``."""
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
    if not 1 <= n <= MAX_N or len(values) != 1 + 2 * (n - 1):
        return -1, b""

    graph = [[] for _ in range(n)]
    dsu = list(range(n))
    sizes = [1] * n

    def find(item):
        while dsu[item] != item:
            dsu[item] = dsu[dsu[item]]
            item = dsu[item]
        return item

    for offset in range(1, len(values), 2):
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

    counts = [0] * n
    for start in range(n):
        distance = [-1] * n
        distance[start] = 0
        pending = deque([start])
        while pending:
            vertex = pending.popleft()
            for neighbor in graph[vertex]:
                if distance[neighbor] == -1:
                    distance[neighbor] = distance[vertex] + 1
                    pending.append(neighbor)
        for target in range(start + 1, n):
            counts[distance[target]] += 1

    output_values = counts[1:]
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
