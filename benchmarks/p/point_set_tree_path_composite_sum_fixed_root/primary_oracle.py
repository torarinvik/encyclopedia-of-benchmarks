"""HLD and segment-tree oracle for dynamic root-zero affine path sums."""

from __future__ import annotations

from collections.abc import Sequence
import struct

MODULUS = 998_244_353
MAX_N = 16
MAX_Q = 32
SEGMENT_BASE = 16
MAX_INPUT_LENGTH = 5 * MAX_N + 4 * MAX_Q - 2
MAX_OUTPUT_BYTES = 8 * MAX_Q
MAX_WORKSPACE_BYTES = 8192
INVALID = -1
OUTPUT_ERROR = -2
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1


def _compose(left: tuple[int, int], right: tuple[int, int]) -> tuple[int, int]:
    """Return left(right(x)) for affine pairs (multiplier, intercept)."""
    return (left[0] * right[0] % MODULUS,
            (left[0] * right[1] + left[1]) % MODULUS)


def _parse(values: Sequence[int] | None, input_is_null: bool,
           input_length: int | None) -> tuple[int, list[int], list[tuple[int, int, int, int]],
                                                list[tuple[int, ...]]] | None:
    if input_is_null or not isinstance(values, (list, tuple)):
        return None
    if not 2 <= len(values) <= MAX_INPUT_LENGTH:
        return None
    if input_length is not None and (type(input_length) is not int or input_length != len(values)):
        return None
    if any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values):
        return None
    n, q = values[0], values[1]
    if not 1 <= n <= MAX_N or not 1 <= q <= MAX_Q:
        return None
    if len(values) < 2 + n + 4 * (n - 1):
        return None
    vertex_values = list(values[2:2 + n])
    if any(not 0 <= value < MODULUS for value in vertex_values):
        return None

    edges: list[tuple[int, int, int, int]] = []
    parent = list(range(n))

    def find(vertex: int) -> int:
        while parent[vertex] != vertex:
            parent[vertex] = parent[parent[vertex]]
            vertex = parent[vertex]
        return vertex

    cursor = 2 + n
    for _ in range(n - 1):
        u, v, multiplier, addend = values[cursor:cursor + 4]
        cursor += 4
        if (not 0 <= u < n or not 0 <= v < n or u == v
                or not 1 <= multiplier < MODULUS or not 0 <= addend < MODULUS):
            return None
        root_u, root_v = find(u), find(v)
        if root_u == root_v:
            return None
        parent[root_v] = root_u
        edges.append((u, v, multiplier, addend))
    if len({find(vertex) for vertex in range(n)}) != 1:
        return None

    operations: list[tuple[int, ...]] = []
    for _ in range(q):
        if cursor >= len(values):
            return None
        kind = values[cursor]
        if kind == 0:
            if cursor + 3 > len(values):
                return None
            vertex, value = values[cursor + 1:cursor + 3]
            if not 0 <= vertex < n or not 0 <= value < MODULUS:
                return None
            operations.append((kind, vertex, value))
            cursor += 3
        elif kind == 1:
            if cursor + 4 > len(values):
                return None
            edge, multiplier, addend = values[cursor + 1:cursor + 4]
            if (not 0 <= edge < n - 1 or not 1 <= multiplier < MODULUS
                    or not 0 <= addend < MODULUS):
                return None
            operations.append((kind, edge, multiplier, addend))
            cursor += 4
        else:
            return None
    if cursor != len(values):
        return None
    return n, vertex_values, edges, operations


def _run_hld(n: int, vertex_values: list[int],
             edges: list[tuple[int, int, int, int]],
             operations: list[tuple[int, ...]]) -> list[int]:
    graph: list[list[tuple[int, int]]] = [[] for _ in range(n)]
    edge_b = [edge[2] for edge in edges]
    edge_c = [edge[3] for edge in edges]
    edge_u = [edge[0] for edge in edges]
    edge_v = [edge[1] for edge in edges]
    for edge_id, (u, v, _b, _c) in enumerate(edges):
        graph[u].append((v, edge_id))
        graph[v].append((u, edge_id))

    parent = [-2] * n
    parent_edge = [-1] * n
    depth = [0] * n
    order = [0]
    parent[0] = -1
    for u in order:
        for v, edge_id in graph[u]:
            if v == parent[u]:
                continue
            parent[v] = u
            parent_edge[v] = edge_id
            depth[v] = depth[u] + 1
            order.append(v)

    subtree_size = [1] * n
    heavy = [-1] * n
    for u in reversed(order):
        best_size = 0
        for v, _edge_id in graph[u]:
            if parent[v] != u:
                continue
            subtree_size[u] += subtree_size[v]
            if (subtree_size[v] > best_size
                    or (subtree_size[v] == best_size and (heavy[u] < 0 or v < heavy[u]))):
                best_size = subtree_size[v]
                heavy[u] = v

    head = [-1] * n
    position = [-1] * n
    chain_end = [-1] * n
    timer = 0
    chain_heads = [0]
    while chain_heads:
        chain_head = chain_heads.pop()
        u = chain_head
        while u >= 0:
            head[u] = chain_head
            position[u] = timer
            timer += 1
            for v, _edge_id in graph[u]:
                if parent[v] == u and v != heavy[u]:
                    chain_heads.append(v)
            u = heavy[u]
        chain_end[chain_head] = timer

    down_sum = [0] * n
    for u in reversed(order):
        total = vertex_values[u]
        for v, edge_id in graph[u]:
            if parent[v] == u:
                total += edge_b[edge_id] * down_sum[v] + edge_c[edge_id] * subtree_size[v]
        down_sum[u] = total % MODULUS

    local_mul = [0] * n
    local_add = [0] * n
    for u in range(n):
        local_add[u] = vertex_values[u]
        for v, edge_id in graph[u]:
            if parent[v] != u:
                continue
            if v == heavy[u]:
                local_mul[u] = edge_b[edge_id]
                local_add[u] += edge_c[edge_id] * subtree_size[v]
            else:
                local_add[u] += edge_b[edge_id] * down_sum[v] + edge_c[edge_id] * subtree_size[v]
        local_add[u] %= MODULUS

    tree: list[tuple[int, int]] = [(1, 0)] * (2 * SEGMENT_BASE)
    for u in range(n):
        tree[SEGMENT_BASE + position[u]] = (local_mul[u], local_add[u])
    for node in range(SEGMENT_BASE - 1, 0, -1):
        tree[node] = _compose(tree[2 * node], tree[2 * node + 1])

    def set_leaf(u: int) -> None:
        node = SEGMENT_BASE + position[u]
        tree[node] = (local_mul[u], local_add[u])
        node //= 2
        while node:
            tree[node] = _compose(tree[2 * node], tree[2 * node + 1])
            node //= 2

    def chain_value(chain_head: int) -> int:
        left = SEGMENT_BASE + position[chain_head]
        right = SEGMENT_BASE + chain_end[chain_head]
        left_result = (1, 0)
        right_result = (1, 0)
        while left < right:
            if left & 1:
                left_result = _compose(left_result, tree[left])
                left += 1
            if right & 1:
                right -= 1
                right_result = _compose(tree[right], right_result)
            left //= 2
            right //= 2
        return _compose(left_result, right_result)[1]

    current_chain_sum = [0] * n
    for u in range(n):
        if head[u] == u:
            current_chain_sum[u] = down_sum[u]

    answers: list[int] = []

    def propagate(start: int) -> None:
        u = start
        while True:
            chain_head = head[u]
            previous = current_chain_sum[chain_head]
            updated = chain_value(chain_head)
            current_chain_sum[chain_head] = updated
            if chain_head == 0:
                return
            p = parent[chain_head]
            edge_id = parent_edge[chain_head]
            local_add[p] = (local_add[p] + edge_b[edge_id] * (updated - previous)) % MODULUS
            set_leaf(p)
            u = p

    for operation in operations:
        if operation[0] == 0:
            _kind, vertex, value = operation
            local_add[vertex] = (local_add[vertex] + value - vertex_values[vertex]) % MODULUS
            vertex_values[vertex] = value
            set_leaf(vertex)
            propagate(vertex)
        else:
            _kind, edge_id, new_b, new_c = operation
            u, v = edge_u[edge_id], edge_v[edge_id]
            child = u if parent[u] == v else v
            p = parent[child]
            old_b, old_c = edge_b[edge_id], edge_c[edge_id]
            if heavy[p] == child:
                local_mul[p] = new_b
                local_add[p] = (local_add[p] + (new_c - old_c) * subtree_size[child]) % MODULUS
            else:
                child_sum = current_chain_sum[child]
                local_add[p] = (local_add[p] + (new_b - old_b) * child_sum
                                + (new_c - old_c) * subtree_size[child]) % MODULUS
            edge_b[edge_id], edge_c[edge_id] = new_b, new_c
            set_leaf(p)
            propagate(p)
        answers.append(current_chain_sum[0])
    return answers


def expected_output(
    values: Sequence[int] | None,
    output_capacity: int | None = None,
    output_is_null: bool = False,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> tuple[int, bytes]:
    if type(output_is_null) is not bool or type(input_is_null) is not bool:
        return INVALID, b""
    parsed = _parse(values, input_is_null, input_length)
    if parsed is None:
        return INVALID, b""
    n, vertex_values, edges, operations = parsed
    byte_count = 8 * len(operations)
    if output_capacity is not None and (
        type(output_capacity) is not int or output_capacity < 0
    ):
        return INVALID, b""
    if output_is_null or (output_capacity is not None and output_capacity < byte_count):
        return OUTPUT_ERROR, b""
    results = _run_hld(n, vertex_values, edges, operations)
    return byte_count, b"".join(struct.pack("<q", value) for value in results)
