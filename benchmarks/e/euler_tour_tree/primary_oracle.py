"""Implicit-treap Euler-tour tree for a bounded dynamic forest workload."""

from __future__ import annotations

from collections.abc import Sequence
import struct

MAX_N = 8
MAX_M = 32
MAX_NODES = MAX_N + 2 * MAX_M
MAX_INPUT_LENGTH = 2 + MAX_N + 3 * MAX_M
MAX_OUTPUT_BYTES = 16 * MAX_M
MAX_WORKSPACE_BYTES = 16384
INVALID = -1
OUTPUT_ERROR = -2
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1


def _reachable(adjacency: list[list[bool]], start: int, target: int) -> bool:
    seen = [False] * len(adjacency)
    stack = [start]
    seen[start] = True
    while stack:
        vertex = stack.pop()
        if vertex == target:
            return True
        for neighbor, linked in enumerate(adjacency[vertex]):
            if linked and not seen[neighbor]:
                seen[neighbor] = True
                stack.append(neighbor)
    return False


def _parse(values, input_is_null: bool, input_length: int | None):
    if input_is_null or not isinstance(values, (list, tuple)):
        return None
    if not 2 <= len(values) <= MAX_INPUT_LENGTH:
        return None
    if input_length is not None and (
        type(input_length) is not int or input_length != len(values)
    ):
        return None
    if any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values):
        return None
    n, m = values[:2]
    if not 1 <= n <= MAX_N or not 1 <= m <= MAX_M or len(values) < 2 + n:
        return None
    weights = list(values[2:2 + n])
    if any(not -100 <= weight <= 100 for weight in weights):
        return None
    cursor = 2 + n
    operations: list[tuple[int, ...]] = []
    query_count = 0
    for _ in range(m):
        if cursor >= len(values):
            return None
        kind = values[cursor]
        if kind in (0, 1):
            if cursor + 3 > len(values):
                return None
            u, v = values[cursor + 1:cursor + 3]
            if not 0 <= u < n or not 0 <= v < n or u == v:
                return None
            operations.append((kind, u, v))
            cursor += 3
        elif kind == 2:
            if cursor + 3 > len(values):
                return None
            vertex, weight = values[cursor + 1:cursor + 3]
            if not 0 <= vertex < n or not -100 <= weight <= 100:
                return None
            operations.append((kind, vertex, weight))
            cursor += 3
        elif kind == 3:
            if cursor + 2 > len(values):
                return None
            vertex = values[cursor + 1]
            if not 0 <= vertex < n:
                return None
            operations.append((kind, vertex))
            query_count += 1
            cursor += 2
        else:
            return None
    if cursor != len(values) or query_count == 0:
        return None

    adjacency = [[False] * n for _ in range(n)]
    for operation in operations:
        kind = operation[0]
        if kind == 0:
            _, u, v = operation
            if _reachable(adjacency, u, v):
                return None
            adjacency[u][v] = adjacency[v][u] = True
        elif kind == 1:
            _, u, v = operation
            if not adjacency[u][v]:
                return None
            adjacency[u][v] = adjacency[v][u] = False
    return n, weights, operations, query_count


def _priority(node: int) -> int:
    value = (node + 0x9E3779B97F4A7C15) & ((1 << 64) - 1)
    value = ((value ^ (value >> 30)) * 0xBF58476D1CE4E5B9) & ((1 << 64) - 1)
    value = ((value ^ (value >> 27)) * 0x94D049BB133111EB) & ((1 << 64) - 1)
    return value ^ (value >> 31)


class _EulerTourTree:
    def __init__(self, weights: list[int]):
        self.left = [-1] * MAX_NODES
        self.right = [-1] * MAX_NODES
        self.parent = [-1] * MAX_NODES
        self.priority = [_priority(i) for i in range(MAX_NODES)]
        self.vertex = [-1] * MAX_NODES
        self.weight = [0] * MAX_NODES
        self.count = [0] * MAX_NODES
        self.total = [0] * MAX_NODES
        self.size = [0] * MAX_NODES
        self.roots = list(range(len(weights)))
        self.next_node = len(weights)
        for vertex, weight in enumerate(weights):
            self.vertex[vertex] = vertex
            self.weight[vertex] = weight
            self.count[vertex] = self.size[vertex] = 1
            self.total[vertex] = weight
        self.edges: list[tuple[int, int, int, int, bool]] = []

    def _subtree_size(self, node: int) -> int:
        return self.size[node] if node >= 0 else 0

    def _subtree_count(self, node: int) -> int:
        return self.count[node] if node >= 0 else 0

    def _subtree_sum(self, node: int) -> int:
        return self.total[node] if node >= 0 else 0

    def _pull(self, node: int) -> None:
        left, right = self.left[node], self.right[node]
        self.size[node] = 1 + self._subtree_size(left) + self._subtree_size(right)
        self.count[node] = (self.vertex[node] >= 0) + self._subtree_count(left) + self._subtree_count(right)
        self.total[node] = self.weight[node] + self._subtree_sum(left) + self._subtree_sum(right)

    def _merge(self, a: int, b: int) -> int:
        if a < 0:
            if b >= 0:
                self.parent[b] = -1
            return b
        if b < 0:
            self.parent[a] = -1
            return a
        if self.priority[a] > self.priority[b]:
            self.right[a] = self._merge(self.right[a], b)
            if self.right[a] >= 0:
                self.parent[self.right[a]] = a
            self._pull(a)
            self.parent[a] = -1
            return a
        self.left[b] = self._merge(a, self.left[b])
        if self.left[b] >= 0:
            self.parent[self.left[b]] = b
        self._pull(b)
        self.parent[b] = -1
        return b

    def _split(self, root: int, prefix_size: int) -> tuple[int, int]:
        if root < 0:
            return -1, -1
        if prefix_size <= self._subtree_size(self.left[root]):
            first, rest = self._split(self.left[root], prefix_size)
            self.left[root] = rest
            if rest >= 0:
                self.parent[rest] = root
            self._pull(root)
            self.parent[root] = -1
            if first >= 0:
                self.parent[first] = -1
            return first, root
        first, rest = self._split(
            self.right[root], prefix_size - self._subtree_size(self.left[root]) - 1
        )
        self.right[root] = first
        if first >= 0:
            self.parent[first] = root
        self._pull(root)
        self.parent[root] = -1
        if rest >= 0:
            self.parent[rest] = -1
        return root, rest

    def _root(self, node: int) -> int:
        while self.parent[node] >= 0:
            node = self.parent[node]
        return node

    def _position(self, node: int) -> int:
        position = self._subtree_size(self.left[node])
        while self.parent[node] >= 0:
            parent = self.parent[node]
            if self.right[parent] == node:
                position += 1 + self._subtree_size(self.left[parent])
            node = parent
        return position

    def _rotate(self, root: int, node: int) -> int:
        position = self._position(node)
        prefix, suffix = self._split(root, position)
        return self._merge(suffix, prefix)

    def link(self, u: int, v: int) -> None:
        root_u = self._rotate(self._root(u), u)
        root_v = self._rotate(self._root(v), v)
        arc_uv, arc_vu = self.next_node, self.next_node + 1
        self.next_node += 2
        for arc in (arc_uv, arc_vu):
            self.vertex[arc] = -1
            self.size[arc] = 1
        root = self._merge(self._merge(self._merge(root_u, arc_uv), root_v), arc_vu)
        self.edges.append((u, v, arc_uv, arc_vu, True))
        self.parent[root] = -1

    def cut(self, u: int, v: int) -> None:
        edge_index = next(
            i for i in range(len(self.edges) - 1, -1, -1)
            if self.edges[i][4] and {self.edges[i][0], self.edges[i][1]} == {u, v}
        )
        a, b, arc_uv, arc_vu, _ = self.edges[edge_index]
        first_arc = arc_uv if (a, b) == (u, v) else arc_vu
        second_arc = arc_vu if first_arc == arc_uv else arc_uv
        root = self._rotate(self._root(first_arc), first_arc)
        _, rest = self._split(root, 1)
        between = self._position(second_arc)
        first_tour, suffix = self._split(rest, between)
        _, second_tour = self._split(suffix, 1)
        if first_tour >= 0:
            self.parent[first_tour] = -1
        if second_tour >= 0:
            self.parent[second_tour] = -1
        self.edges[edge_index] = (a, b, arc_uv, arc_vu, False)

    def set_weight(self, vertex: int, weight: int) -> None:
        self.weight[vertex] = weight
        self._pull_to_root(vertex)

    def _pull_to_root(self, node: int) -> None:
        path = []
        while node >= 0:
            path.append(node)
            node = self.parent[node]
        for node in path:
            self._pull(node)

    def component(self, vertex: int) -> tuple[int, int]:
        root = self._root(vertex)
        return self.count[root], self.total[root]


def _run(n: int, weights: list[int], operations: list[tuple[int, ...]]) -> list[int]:
    tree = _EulerTourTree(weights)
    answers = []
    for operation in operations:
        kind = operation[0]
        if kind == 0:
            tree.link(operation[1], operation[2])
        elif kind == 1:
            tree.cut(operation[1], operation[2])
        elif kind == 2:
            tree.set_weight(operation[1], operation[2])
        else:
            answers.extend(tree.component(operation[1]))
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
    if output_capacity is not None and (
        type(output_capacity) is not int or output_capacity < 0
    ):
        return INVALID, b""
    n, weights, operations, query_count = parsed
    required = 16 * query_count
    if output_is_null or (output_capacity is not None and output_capacity < required):
        return OUTPUT_ERROR, b""
    answers = _run(n, weights, operations)
    return required, b"".join(struct.pack("<q", answer) for answer in answers)
