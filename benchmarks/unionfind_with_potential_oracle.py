"""Independent graph-traversal oracle for modular potential union-find."""

from collections import deque
import struct

MOD = 998_244_353
MAX_N = 64
MAX_Q = 256
MAX_PARSEABLE_INPUT_LENGTH = 2 + 4 * MAX_Q
MAX_OUTPUT_BYTES = 8 * MAX_Q


def _difference(graph, start, target):
    """Return a_target-a_start along accepted equations, or None if disconnected."""
    offsets = {start: 0}
    pending = deque([start])
    while pending:
        node = pending.popleft()
        if node == target:
            return offsets[node]
        for neighbor, delta in graph[node]:
            if neighbor not in offsets:
                offsets[neighbor] = (offsets[node] + delta) % MOD
                pending.append(neighbor)
    return None


def expected_output(values, capacity=None, output_is_null=False,
                    input_is_null=False, input_length=None):
    """Return ``(result, bytes)`` for ``[N,Q,(type,u,v,x)...]`` records."""
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
    if len(values) != 2 + 4 * q:
        return -1, b""

    operations = []
    for offset in range(2, len(values), 4):
        kind, u, v, x = values[offset:offset + 4]
        if not (0 <= u < n and 0 <= v < n):
            return -1, b""
        if kind == 0:
            if not 0 <= x < MOD:
                return -1, b""
        elif kind == 1:
            if x != 0:
                return -1, b""
        else:
            return -1, b""
        operations.append((kind, u, v, x))

    required = 8 * q
    effective_capacity = MAX_OUTPUT_BYTES if capacity is None else capacity
    if (type(output_is_null) is not bool
            or type(effective_capacity) is not int
            or effective_capacity < 0):
        return -2, b""
    if output_is_null or effective_capacity < required:
        return -2, b""

    graph = [[] for _ in range(n)]
    answers = []
    for kind, u, v, x in operations:
        if kind == 0:
            known = _difference(graph, v, u)
            if known is None:
                # Each edge stores a_neighbor - a_node.
                graph[v].append((u, x))
                graph[u].append((v, (-x) % MOD))
                answers.append(1)
            else:
                answers.append(int(known == x))
        else:
            difference = _difference(graph, v, u)
            answers.append(-1 if difference is None else difference)

    output = b"".join(struct.pack("<q", answer) for answer in answers)
    return len(output), output
