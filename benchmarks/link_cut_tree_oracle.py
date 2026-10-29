"""Independent BFS oracle for the bounded link-cut-tree workload."""

from __future__ import annotations

from collections import deque

MAX_VERTICES = 16
MAX_OPERATIONS = 64
MAX_INPUT_LENGTH = 210
MAX_OUTPUT_BYTES = 8 * MAX_OPERATIONS
WEIGHT_LIMIT = 1_000_000


def _parse(values: list[int] | tuple[int, ...]) -> tuple[int, list[int], list[tuple[int, int, int]]] | None:
    if len(values) < 2:
        return None
    n, operation_count = values[:2]
    if not 1 <= n <= MAX_VERTICES or not 1 <= operation_count <= MAX_OPERATIONS:
        return None
    if len(values) != 2 + n + 3 * operation_count or len(values) > MAX_INPUT_LENGTH:
        return None
    weights = list(values[2:2 + n])
    if any(weight < 0 or weight > WEIGHT_LIMIT for weight in weights):
        return None
    operations: list[tuple[int, int, int]] = []
    offset = 2 + n
    for index in range(operation_count):
        operation, u, v = values[offset + 3 * index:offset + 3 * index + 3]
        if operation not in (0, 1, 2) or not (0 <= u < n and 0 <= v < n):
            return None
        operations.append((operation, u, v))
    return n, weights, operations


def _path(adjacency: list[set[int]], start: int, target: int) -> list[int] | None:
    parent = [-1] * len(adjacency)
    parent[start] = start
    queue = deque([start])
    while queue:
        vertex = queue.popleft()
        if vertex == target:
            break
        for neighbor in adjacency[vertex]:
            if parent[neighbor] == -1:
                parent[neighbor] = vertex
                queue.append(neighbor)
    if parent[target] == -1:
        return None
    result = [target]
    while result[-1] != start:
        result.append(parent[result[-1]])
    return result


def evaluate(values: list[int] | tuple[int, ...]) -> list[int] | None:
    parsed = _parse(values)
    if parsed is None:
        return None
    n, weights, operations = parsed
    adjacency = [set() for _ in range(n)]
    results: list[int] = []
    for operation, u, v in operations:
        path = _path(adjacency, u, v)
        if operation == 0:
            if u != v and path is None:
                adjacency[u].add(v)
                adjacency[v].add(u)
                results.append(1)
            else:
                results.append(0)
        elif operation == 1:
            if u != v and v in adjacency[u]:
                adjacency[u].remove(v)
                adjacency[v].remove(u)
                results.append(1)
            else:
                results.append(0)
        elif path is None:
            results.append(-1)
        else:
            results.append(sum(weights[vertex] for vertex in path))
    return results


def _encode_i64(values: list[int]) -> bytes:
    return b"".join(int(value).to_bytes(8, "little", signed=True) for value in values)


def expected_output(
    values: list[int] | tuple[int, ...] | None,
    output_capacity: int | None = None,
    output_is_null: bool = False,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> tuple[int, bytes]:
    if input_is_null or values is None:
        return -1, b""
    if input_length is not None and input_length != len(values):
        return -1, b""
    outputs = evaluate(values)
    if outputs is None:
        return -1, b""
    encoded = _encode_i64(outputs)
    if output_is_null or (output_capacity is not None and output_capacity < len(encoded)):
        return -2, b""
    return len(encoded), encoded
