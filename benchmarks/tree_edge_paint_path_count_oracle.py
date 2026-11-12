"""Primary Euler-tour directional segment-tree oracle for tree edge painting."""

from __future__ import annotations

from collections.abc import Sequence

MAX_N = 16
MAX_QUERIES = 32
MAX_VALID_INPUT_LENGTH = 2 + 2 * (MAX_N - 1) + 3 * MAX_QUERIES
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
INVALID_RESULT = -1


class _SegmentTree:
    def __init__(self, length: int) -> None:
        self.base = 1
        while self.base < max(1, length):
            self.base *= 2
        self.data = [0] * (2 * self.base)

    def set(self, index: int, value: int) -> None:
        position = self.base + index
        self.data[position] = value
        position //= 2
        while position:
            self.data[position] = self.data[position * 2] + self.data[position * 2 + 1]
            position //= 2

    def sum(self, left: int, right: int) -> int:
        if left > right:
            return 0
        left += self.base
        right += self.base
        total = 0
        while left <= right:
            if left & 1:
                total += self.data[left]
                left += 1
            if not (right & 1):
                total += self.data[right]
                right -= 1
            left //= 2
            right //= 2
        return total


def _parse(values: Sequence[int] | None):
    if not isinstance(values, (list, tuple)) or not 2 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH:
        return None
    if any(type(value) is not int or not -(1 << 63) <= value < (1 << 63) for value in values):
        return None
    n, q = values[0], values[1]
    if not 1 <= n <= MAX_N or not 0 <= q <= MAX_QUERIES:
        return None
    edge_count = n - 1
    expected_length = 2 + 2 * edge_count + 3 * q
    if len(values) != expected_length:
        return None
    edges = []
    dsu = list(range(n))

    def find(node: int) -> int:
        while dsu[node] != node:
            dsu[node] = dsu[dsu[node]]
            node = dsu[node]
        return node

    cursor = 2
    for _ in range(edge_count):
        u, v = values[cursor], values[cursor + 1]
        cursor += 2
        if not 0 <= u < n or not 0 <= v < n or u == v:
            return None
        left, right = find(u), find(v)
        if left == right:
            return None
        dsu[left] = right
        edges.append((u, v))
    if any(find(node) != find(0) for node in range(n)):
        return None
    operations = []
    for _ in range(q):
        kind, a, b = values[cursor], values[cursor + 1], values[cursor + 2]
        cursor += 3
        if kind == 0:
            if not 0 <= a < edge_count or b != 0:
                return None
        elif kind == 1:
            if not 0 <= a < n or not 0 <= b < n:
                return None
        else:
            return None
        operations.append((kind, a, b))
    return n, edges, operations


def expected_result(values: Sequence[int] | None) -> int:
    parsed = _parse(values)
    if parsed is None:
        return INVALID_RESULT
    n, edges, operations = parsed
    edge_count = len(edges)

    # Build the rooted Euler walk without storing a graph-specific traversal.
    visited = [False] * n
    parent = [0] * n
    depth = [0] * n
    first = [0] * n
    down_position = [-1] * edge_count
    up_position = [-1] * edge_count
    occurrence_count = 0
    visited[0] = True
    stack_node = [0]
    stack_parent = [-1]
    stack_incoming = [-1]
    stack_cursor = [0]
    while stack_node:
        node = stack_node[-1]
        found = False
        while stack_cursor[-1] < edge_count:
            edge_id = stack_cursor[-1]
            stack_cursor[-1] += 1
            left, right = edges[edge_id]
            if left != node and right != node:
                continue
            child = right if left == node else left
            if child == stack_parent[-1]:
                continue
            if visited[child]:
                return INVALID_RESULT
            visited[child] = True
            parent[child] = node
            depth[child] = depth[node] + 1
            down_position[edge_id] = occurrence_count
            occurrence_count += 1
            first[child] = occurrence_count
            stack_node.append(child)
            stack_parent.append(node)
            stack_incoming.append(edge_id)
            stack_cursor.append(0)
            found = True
            break
        if found:
            continue
        incoming = stack_incoming.pop()
        stack_node.pop()
        stack_parent.pop()
        stack_cursor.pop()
        if incoming >= 0:
            up_position[incoming] = occurrence_count
            occurrence_count += 1

    levels = 5
    ancestor = [parent[:]]
    for _ in range(1, levels):
        previous = ancestor[-1]
        ancestor.append([previous[previous[node]] for node in range(n)])

    def lca(left: int, right: int) -> int:
        if depth[left] < depth[right]:
            left, right = right, left
        difference = depth[left] - depth[right]
        bit = 0
        while difference:
            if difference & 1:
                left = ancestor[bit][left]
            difference >>= 1
            bit += 1
        if left == right:
            return left
        for bit in range(levels - 1, -1, -1):
            if ancestor[bit][left] != ancestor[bit][right]:
                left = ancestor[bit][left]
                right = ancestor[bit][right]
        return parent[left]

    forward = _SegmentTree(occurrence_count)
    backward = _SegmentTree(occurrence_count)
    painted = [False] * edge_count

    def path_to_ancestor(node: int, ancestor_node: int) -> int:
        left, right = first[ancestor_node], first[node] - 1
        return forward.sum(left, right) - backward.sum(left, right)

    total = 0
    for kind, a, b in operations:
        if kind == 0:
            if not painted[a]:
                painted[a] = True
                forward.set(down_position[a], 1)
                backward.set(up_position[a], 1)
        else:
            common = lca(a, b)
            total += path_to_ancestor(a, common) + path_to_ancestor(b, common)
    return total
