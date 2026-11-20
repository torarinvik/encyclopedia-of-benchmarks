"""Right-boundary range-union DSU oracle for the bounded profile."""

from __future__ import annotations

from collections.abc import Sequence

MAX_N = 32
MAX_Q = 32
MAX_PARSEABLE_INPUT_LENGTH = 99


def _decode(values: Sequence[int] | None):
    if values is None or not isinstance(values, (list, tuple)):
        return None
    if not 2 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH:
        return None
    if any(type(value) is not int or not -(1 << 63) <= value < (1 << 63) for value in values):
        return None
    n, q = values[:2]
    if not 1 <= n <= MAX_N or not 0 <= q <= MAX_Q or len(values) != 2 + 3 * q:
        return None
    operations = []
    for offset in range(2, len(values), 3):
        opcode, first, second = values[offset:offset + 3]
        if opcode == 0:
            if not 0 <= first <= second <= n:
                return None
        elif opcode == 1:
            if not (0 <= first < n and 0 <= second < n):
                return None
        elif opcode == 2:
            if not (0 <= first < n and second == 0):
                return None
        else:
            return None
        operations.append((opcode, first, second))
    return n, operations


def run(values: Sequence[int] | None) -> int:
    decoded = _decode(values)
    if decoded is None:
        return -1
    n, operations = decoded
    parent = [-1] * n
    left = list(range(n))
    right = [vertex + 1 for vertex in range(n)]
    components = n

    def find(vertex: int) -> int:
        while parent[vertex] >= 0:
            ancestor = parent[vertex]
            if parent[ancestor] >= 0:
                parent[vertex] = parent[ancestor]
            vertex = ancestor
        return vertex

    def unite_roots(root_a: int, root_b: int) -> int:
        if parent[root_a] > parent[root_b]:
            root_a, root_b = root_b, root_a
        parent[root_a] += parent[root_b]
        parent[root_b] = root_a
        left[root_a] = min(left[root_a], left[root_b])
        right[root_a] = max(right[root_a], right[root_b])
        return root_a

    total = 0
    for operation_index, (opcode, first, second) in enumerate(operations, start=1):
        if opcode == 0:
            if first < second:
                root = find(first)
                next_component = right[root]
                while next_component < second:
                    next_root = find(next_component)
                    if root != next_root:
                        root = unite_roots(root, next_root)
                        components -= 1
                    else:
                        root = next_root
                    next_component = right[root]
            observed = components
        elif opcode == 1:
            observed = int(find(first) == find(second))
        else:
            observed = -parent[find(first)]
        total += operation_index * observed
    return total


def expected_result(
    values: Sequence[int] | None,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> int:
    if type(input_is_null) is not bool or type(input_length) not in (int, type(None)):
        return -1
    if input_is_null or values is None or not isinstance(values, (list, tuple)):
        return -1
    if input_length is None:
        input_length = len(values)
    if input_length < 0 or input_length > len(values) or input_length > MAX_PARSEABLE_INPUT_LENGTH:
        return -1
    return run(values[:input_length])
