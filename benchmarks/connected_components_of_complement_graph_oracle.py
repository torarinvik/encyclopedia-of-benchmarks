"""Direct-complement BFS oracle for complement connected components."""

from collections import deque
import struct

MAX_N = 64
MAX_M = MAX_N * (MAX_N - 1) // 2
MAX_PARSEABLE_INPUT_LENGTH = 2 + 2 * MAX_M
MAX_OUTPUT_BYTES = 8 * (1 + 2 * MAX_N)


def expected_output(values, capacity=None, output_is_null=False,
                    input_is_null=False, input_length=None):
    """Return ``(result, bytes)`` for ``[N,M,(u,v)...]``."""
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
    n, m = values[:2]
    if not 1 <= n <= MAX_N or not 0 <= m <= n * (n - 1) // 2:
        return -1, b""
    if len(values) != 2 + 2 * m:
        return -1, b""
    adjacency = [set() for _ in range(n)]
    for offset in range(2, len(values), 2):
        left, right = values[offset:offset + 2]
        if (not 0 <= left < n or not 0 <= right < n or left == right
                or right in adjacency[left]):
            return -1, b""
        adjacency[left].add(right)
        adjacency[right].add(left)

    unseen = set(range(n))
    components = []
    while unseen:
        root = min(unseen)
        unseen.remove(root)
        pending = deque([root])
        component = [root]
        while pending:
            vertex = pending.popleft()
            for candidate in sorted(unseen):
                if candidate not in adjacency[vertex]:
                    unseen.remove(candidate)
                    component.append(candidate)
                    pending.append(candidate)
        components.append(sorted(component))

    output_values = [len(components)]
    for component in components:
        output_values.append(len(component))
        output_values.extend(component)
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
