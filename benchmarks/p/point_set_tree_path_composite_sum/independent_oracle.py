"""Direct path traversal oracle for arbitrary-root affine tree aggregates."""

from __future__ import annotations

from collections.abc import Sequence

MODULUS = 998244353
MAX_VERTICES = 16
MAX_OPERATIONS = 32
MAX_INPUT_LENGTH = 2 + MAX_VERTICES + 4 * (MAX_VERTICES - 1) + 5 * MAX_OPERATIONS
MAX_OUTPUT_BYTES = 8 * MAX_OPERATIONS
INVALID_RESULT = -1
OUTPUT_ERROR = -2


def _compose(outer: tuple[int, int], inner: tuple[int, int]) -> tuple[int, int]:
    return (outer[0] * inner[0] % MODULUS,
            (outer[0] * inner[1] + outer[1]) % MODULUS)


def _read_input(values: Sequence[int] | None, input_length: int | None,
                input_is_null: bool):
    if type(input_is_null) is not bool or input_is_null or not isinstance(values, (list, tuple)):
        return None
    length = len(values) if input_length is None else input_length
    if type(length) is not int or length != len(values) or not 2 <= length <= MAX_INPUT_LENGTH:
        return None
    if any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
           for value in values):
        return None
    n, q = values[0], values[1]
    if not 1 <= n <= MAX_VERTICES or not 1 <= q <= MAX_OPERATIONS:
        return None
    at = 2
    vertex_values = list(values[at:at + n])
    at += n
    if len(vertex_values) != n or any(value < 0 or value >= MODULUS for value in vertex_values):
        return None
    edges: list[tuple[int, int, int, int]] = []
    parent = list(range(n))

    def find(x: int) -> int:
        while parent[x] != x:
            parent[x] = parent[parent[x]]
            x = parent[x]
        return x

    for _ in range(n - 1):
        if at + 4 > length:
            return None
        u, v, multiplier, addend = values[at:at + 4]
        at += 4
        if not (0 <= u < n and 0 <= v < n and u != v):
            return None
        if not (1 <= multiplier < MODULUS and 0 <= addend < MODULUS):
            return None
        ru, rv = find(u), find(v)
        if ru == rv:
            return None
        parent[ru] = rv
        edges.append((u, v, multiplier, addend))
    if any(find(v) != find(0) for v in range(n)):
        return None

    operations: list[tuple[int, int, int, int, int]] = []
    for _ in range(q):
        if at >= length:
            return None
        opcode = values[at]
        at += 1
        if opcode == 0:
            if at + 3 > length:
                return None
            vertex, value, root = values[at:at + 3]
            at += 3
            if not (0 <= vertex < n and 0 <= value < MODULUS and 0 <= root < n):
                return None
            operations.append((0, vertex, value, 0, root))
        elif opcode == 1:
            if at + 4 > length:
                return None
            edge, multiplier, addend, root = values[at:at + 4]
            at += 4
            if not (0 <= edge < n - 1 and 1 <= multiplier < MODULUS
                    and 0 <= addend < MODULUS and 0 <= root < n):
                return None
            operations.append((1, edge, multiplier, addend, root))
        else:
            return None
    if at != length:
        return None
    return n, vertex_values, edges, operations


def expected_output(values: Sequence[int] | None, output_capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    parsed = _read_input(values, input_length, input_is_null)
    if parsed is None:
        return INVALID_RESULT, b""
    n, vertex_values, edge_records, operations = parsed
    if type(output_is_null) is not bool:
        return OUTPUT_ERROR, b""
    if output_capacity is None:
        capacity = MAX_OUTPUT_BYTES
    elif type(output_capacity) is not int or output_capacity < 0:
        return OUTPUT_ERROR, b""
    else:
        capacity = output_capacity
    required = 8 * len(operations)
    if output_is_null or capacity < required:
        return OUTPUT_ERROR, b""

    edge_maps = [(record[2], record[3]) for record in edge_records]
    adjacency: list[list[tuple[int, int]]] = [[] for _ in range(n)]
    for edge_id, (u, v, _, _) in enumerate(edge_records):
        adjacency[u].append((v, edge_id))
        adjacency[v].append((u, edge_id))

    answers: list[int] = []
    for opcode, item, first, second, root in operations:
        if opcode == 0:
            vertex_values[item] = first
        else:
            edge_maps[item] = (first, second)

        total = 0
        stack = [(root, -1, (1, 0))]
        while stack:
            vertex, previous, transform = stack.pop()
            total = (total + transform[0] * vertex_values[vertex] + transform[1]) % MODULUS
            for neighbor, edge_id in adjacency[vertex]:
                if neighbor == previous:
                    continue
                # The edge nearest the current root is the outer map. Extending
                # the path appends this undirected edge map inside the prefix.
                stack.append((neighbor, vertex,
                              _compose(transform, edge_maps[edge_id])))
        answers.append(total)
    output = b"".join(answer.to_bytes(8, "little", signed=True) for answer in answers)
    return len(output), output
