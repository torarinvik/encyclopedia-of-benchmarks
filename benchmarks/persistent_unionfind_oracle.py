"""Independent explicit-graph oracle for the persistent union-find profile."""

from collections import deque
import struct

MAX_N = 64
MAX_Q = 64
MAX_PARSEABLE_INPUT_LENGTH = 2 + 4 * MAX_Q
MAX_OUTPUT_BYTES = 8 * MAX_Q


def _connected(n, edges, start, target):
    if start == target:
        return 1
    adjacency = [[] for _ in range(n)]
    for left, right in edges:
        adjacency[left].append(right)
        adjacency[right].append(left)
    seen = [False] * n
    seen[start] = True
    pending = deque([start])
    while pending:
        vertex = pending.popleft()
        for neighbor in adjacency[vertex]:
            if neighbor == target:
                return 1
            if not seen[neighbor]:
                seen[neighbor] = True
                pending.append(neighbor)
    return 0


def expected_output(values, capacity=None, output_is_null=False,
                    input_is_null=False, input_length=None):
    """Return ``(result, bytes)`` for ``[N,Q,(t,k,u,v)...]``."""
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

    records = []
    for index in range(q):
        record = values[2 + 4 * index: 6 + 4 * index]
        kind, parent, left, right = record
        if kind not in (0, 1) or not -1 <= parent < index:
            return -1, b""
        if not 0 <= left < n or not 0 <= right < n:
            return -1, b""
        if parent >= 0 and records[parent][0] != 0:
            return -1, b""
        records.append(record)

    query_count = sum(kind == 1 for kind, _, _, _ in records)
    required = 8 * query_count
    effective_capacity = MAX_OUTPUT_BYTES if capacity is None else capacity
    if (type(output_is_null) is not bool
            or type(effective_capacity) is not int
            or effective_capacity < 0):
        return -2, b""
    if output_is_null or effective_capacity < required:
        return -2, b""

    versions = {-1: []}
    answers = []
    for index, (kind, parent, left, right) in enumerate(records):
        if kind == 0:
            new_edges = list(versions[parent])
            new_edges.append((left, right))
            versions[index] = new_edges
        else:
            answers.append(_connected(n, versions[parent], left, right))

    output = b"".join(struct.pack("<q", answer) for answer in answers)
    return len(output), output
