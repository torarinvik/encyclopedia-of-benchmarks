"""Independent all-pairs tree-traversal oracle for dynamic edge weights."""

from __future__ import annotations

from collections.abc import Sequence

MAX_VERTICES = 16
MAX_OPERATIONS = 32
MAX_WEIGHT = 1000
MAX_OUTPUT_BYTES = 8 * MAX_OPERATIONS
INVALID_RESULT = -1
OUTPUT_ERROR = -2


def _decode(values: Sequence[int] | None, input_length: int | None,
            input_is_null: bool) -> tuple[int, list[tuple[int, int, int]], list[tuple[int, int, int]]] | None:
    if type(input_is_null) is not bool or input_is_null:
        return None
    if input_length is not None and (type(input_length) is not int or input_length < 0):
        return None
    if not isinstance(values, (list, tuple)):
        return None
    actual_length = len(values) if input_length is None else input_length
    if actual_length != len(values) or actual_length < 2:
        return None
    if any(type(value) is not int or value < -(1 << 63) or value >= (1 << 63)
           for value in values):
        return None
    n, q = values[0], values[1]
    if not 1 <= n <= MAX_VERTICES or not 0 <= q <= MAX_OPERATIONS:
        return None
    edge_end = 2 + 3 * (n - 1)
    if actual_length != edge_end + 3 * q:
        return None
    edges: list[tuple[int, int, int]] = []
    parent = list(range(n))

    def root(x: int) -> int:
        while parent[x] != x:
            parent[x] = parent[parent[x]]
            x = parent[x]
        return x

    for edge_id in range(n - 1):
        offset = 2 + 3 * edge_id
        u, v, weight = values[offset:offset + 3]
        if not 0 <= u < n or not 0 <= v < n or u == v or not 0 <= weight <= MAX_WEIGHT:
            return None
        ru, rv = root(u), root(v)
        if ru == rv:
            return None
        parent[ru] = rv
        edges.append((u, v, weight))
    if any(root(vertex) != root(0) for vertex in range(n)):
        return None

    operations: list[tuple[int, int, int]] = []
    for index in range(q):
        opcode, edge_id, value = values[edge_end + 3 * index:edge_end + 3 * index + 3]
        if opcode == 0:
            if not 0 <= edge_id < n - 1 or not 0 <= value <= MAX_WEIGHT:
                return None
        elif opcode == 1:
            if edge_id != 0 or value != 0:
                return None
        else:
            return None
        operations.append((opcode, edge_id, value))
    return n, edges, operations


def expected_output(values: Sequence[int] | None, output_capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    parsed = _decode(values, input_length, input_is_null)
    if parsed is None:
        return INVALID_RESULT, b""
    n, edges, operations = parsed
    query_count = sum(opcode == 1 for opcode, _, _ in operations)
    required = 8 * query_count
    if type(output_is_null) is not bool:
        return OUTPUT_ERROR, b""
    if output_capacity is None:
        capacity = MAX_OUTPUT_BYTES
    elif type(output_capacity) is not int or output_capacity < 0:
        return OUTPUT_ERROR, b""
    else:
        capacity = output_capacity
    if required > 0 and (output_is_null or capacity < required):
        return OUTPUT_ERROR, b""

    adjacency: list[list[tuple[int, int]]] = [[] for _ in range(n)]
    weights: list[int] = []
    for edge_id, (u, v, weight) in enumerate(edges):
        adjacency[u].append((v, edge_id))
        adjacency[v].append((u, edge_id))
        weights.append(weight)
    answers: list[int] = []
    for opcode, edge_id, value in operations:
        if opcode == 0:
            weights[edge_id] = value
            continue
        diameter = 0
        for source in range(n):
            stack = [(source, -1, 0)]
            while stack:
                vertex, previous, distance = stack.pop()
                if distance > diameter:
                    diameter = distance
                for neighbor, path_edge in adjacency[vertex]:
                    if neighbor != previous:
                        stack.append((neighbor, vertex, distance + weights[path_edge]))
        answers.append(diameter)
    output = b"".join(answer.to_bytes(8, "little", signed=True) for answer in answers)
    return len(output), output
