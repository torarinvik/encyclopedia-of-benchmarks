"""Independent explicit-graph oracle for range-parallel union-find."""

from collections import deque
import struct

MOD = 998_244_353
MAX_N = 64
MAX_Q = 64
MAX_PARSEABLE_INPUT_LENGTH = 2 + MAX_N + 3 * MAX_Q
MAX_OUTPUT_BYTES = 8 * MAX_Q


def _component_labels(graph):
    labels = [-1] * len(graph)
    component = 0
    for start in range(len(graph)):
        if labels[start] >= 0:
            continue
        labels[start] = component
        pending = deque([start])
        while pending:
            vertex = pending.popleft()
            for neighbor in graph[vertex]:
                if labels[neighbor] < 0:
                    labels[neighbor] = component
                    pending.append(neighbor)
        component += 1
    return labels


def expected_output(values, capacity=None, output_is_null=False,
                    input_is_null=False, input_length=None):
    """Return ``(result, bytes)`` for ``[N,Q,weights...,(k,a,b)...]``."""
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
    if len(values) != 2 + n + 3 * q:
        return -1, b""
    weights = values[2:2 + n]
    if any(weight < 0 or weight >= MOD for weight in weights):
        return -1, b""
    operations = []
    for offset in range(2 + n, len(values), 3):
        length, left, right = values[offset:offset + 3]
        if not 0 <= length <= n or not 0 <= left <= n - length or not 0 <= right <= n - length:
            return -1, b""
        operations.append((length, left, right))

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
    for length, left, right in operations:
        for offset in range(length):
            u = left + offset
            v = right + offset
            graph[u].append(v)
            graph[v].append(u)
        labels = _component_labels(graph)
        answer = 0
        for u in range(n):
            for v in range(u + 1, n):
                if labels[u] == labels[v]:
                    answer = (answer + weights[u] * weights[v]) % MOD
        answers.append(answer)

    output = b"".join(struct.pack("<q", answer) for answer in answers)
    return len(output), output
