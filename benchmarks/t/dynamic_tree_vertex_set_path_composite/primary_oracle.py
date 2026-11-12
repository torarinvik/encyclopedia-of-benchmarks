"""Link-Cut Tree oracle for dynamic oriented affine path composition."""

from __future__ import annotations

from collections import deque
from collections.abc import Sequence
import struct

MODULUS = 998_244_353
MAX_N = 8
MAX_Q = 12
MAX_VALID_INPUT_LENGTH = 4 * MAX_N + 5 * MAX_Q
MAX_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_OUTPUT_BYTES = 8 * MAX_Q
INVALID = -1
OUTPUT_ERROR = -2
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1
IDENTITY = (1, 0)


def _compose(after: tuple[int, int], before: tuple[int, int]) -> tuple[int, int]:
    return (after[0] * before[0] % MODULUS,
            (after[0] * before[1] + after[1]) % MODULUS)


class _Node:
    __slots__ = ("child", "parent", "reversed", "value", "forward", "backward")

    def __init__(self, value: tuple[int, int]):
        self.child = [-1, -1]
        self.parent = -1
        self.reversed = False
        self.value = value
        self.forward = value
        self.backward = value


class _LinkCutTree:
    def __init__(self, values: list[tuple[int, int]]):
        self.nodes = [_Node(value) for value in values]

    def _is_root(self, x: int) -> bool:
        parent = self.nodes[x].parent
        return parent < 0 or self.nodes[parent].child[0] != x and self.nodes[parent].child[1] != x

    def _pull(self, x: int) -> None:
        node = self.nodes[x]
        left, right = node.child
        left_forward = IDENTITY if left < 0 else self.nodes[left].forward
        right_forward = IDENTITY if right < 0 else self.nodes[right].forward
        left_backward = IDENTITY if left < 0 else self.nodes[left].backward
        right_backward = IDENTITY if right < 0 else self.nodes[right].backward
        node.forward = _compose(right_forward, _compose(node.value, left_forward))
        node.backward = _compose(left_backward, _compose(node.value, right_backward))

    def _reverse(self, x: int) -> None:
        if x < 0:
            return
        node = self.nodes[x]
        node.child[0], node.child[1] = node.child[1], node.child[0]
        node.forward, node.backward = node.backward, node.forward
        node.reversed = not node.reversed

    def _push(self, x: int) -> None:
        node = self.nodes[x]
        if node.reversed:
            self._reverse(node.child[0])
            self._reverse(node.child[1])
            node.reversed = False

    def _rotate(self, x: int) -> None:
        node = self.nodes[x]
        parent = node.parent
        grand = self.nodes[parent].parent
        direction = int(self.nodes[parent].child[1] == x)
        middle = node.child[direction ^ 1]
        if not self._is_root(parent):
            self.nodes[grand].child[int(self.nodes[grand].child[1] == parent)] = x
        node.parent = grand
        node.child[direction ^ 1] = parent
        self.nodes[parent].parent = x
        self.nodes[parent].child[direction] = middle
        if middle >= 0:
            self.nodes[middle].parent = parent
        self._pull(parent)
        self._pull(x)

    def _splay(self, x: int) -> None:
        ancestors = [x]
        while not self._is_root(ancestors[-1]):
            ancestors.append(self.nodes[ancestors[-1]].parent)
        for ancestor in reversed(ancestors):
            self._push(ancestor)
        while not self._is_root(x):
            parent = self.nodes[x].parent
            if not self._is_root(parent):
                grand = self.nodes[parent].parent
                zig_zig = (self.nodes[parent].child[0] == x) == (self.nodes[grand].child[0] == parent)
                self._rotate(parent if zig_zig else x)
            self._rotate(x)

    def _access(self, x: int) -> None:
        last = -1
        y = x
        while y >= 0:
            self._splay(y)
            self.nodes[y].child[1] = last
            if last >= 0:
                self.nodes[last].parent = y
            self._pull(y)
            last = y
            y = self.nodes[y].parent
        self._splay(x)

    def make_root(self, x: int) -> None:
        self._access(x)
        self._reverse(x)

    def find_root(self, x: int) -> int:
        self._access(x)
        self._push(x)
        while self.nodes[x].child[0] >= 0:
            x = self.nodes[x].child[0]
            self._push(x)
        self._splay(x)
        return x

    def link(self, u: int, v: int) -> bool:
        if u == v:
            return False
        self.make_root(u)
        if self.find_root(v) == u:
            return False
        self.nodes[u].parent = v
        return True

    def cut(self, u: int, v: int) -> bool:
        if u == v:
            return False
        self.make_root(u)
        self._access(v)
        if self.nodes[v].child[0] != u or self.nodes[u].child[1] >= 0:
            return False
        self.nodes[v].child[0] = -1
        self.nodes[u].parent = -1
        self._pull(v)
        return True

    def set_value(self, vertex: int, value: tuple[int, int]) -> None:
        self._access(vertex)
        self.nodes[vertex].value = value
        self._pull(vertex)

    def path(self, u: int, v: int) -> tuple[int, int] | None:
        self.make_root(u)
        if self.find_root(v) != u:
            return None
        self.make_root(u)
        self._access(v)
        return self.nodes[v].forward


def _reachable(adjacency: list[set[int]], start: int, target: int) -> bool:
    seen = {start}
    queue = deque([start])
    while queue:
        vertex = queue.popleft()
        if vertex == target:
            return True
        for neighbor in adjacency[vertex]:
            if neighbor not in seen:
                seen.add(neighbor)
                queue.append(neighbor)
    return False


def _parse(values: Sequence[int] | None, input_is_null: bool, input_length: int | None):
    if input_is_null or not isinstance(values, (list, tuple)):
        return None
    if len(values) < 2 or len(values) > MAX_INPUT_LENGTH:
        return None
    if input_length is not None and (type(input_length) is not int or input_length != len(values)):
        return None
    if any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values):
        return None
    n, q = values[:2]
    if not 1 <= n <= MAX_N or not 1 <= q <= MAX_Q:
        return None
    if len(values) < 2 + 2 * n + 2 * (n - 1) + 4 * q:
        return None
    affine_values = []
    cursor = 2
    for _ in range(n):
        multiplier, addend = values[cursor : cursor + 2]
        cursor += 2
        if not 1 <= multiplier < MODULUS or not 0 <= addend < MODULUS:
            return None
        affine_values.append((multiplier, addend))

    adjacency = [set() for _ in range(n)]
    dsu = list(range(n))

    def find(vertex: int) -> int:
        while dsu[vertex] != vertex:
            dsu[vertex] = dsu[dsu[vertex]]
            vertex = dsu[vertex]
        return vertex

    edges = []
    for _ in range(n - 1):
        u, v = values[cursor : cursor + 2]
        cursor += 2
        if not 0 <= u < n or not 0 <= v < n or u == v:
            return None
        root_u, root_v = find(u), find(v)
        if root_u == root_v:
            return None
        dsu[root_v] = root_u
        adjacency[u].add(v)
        adjacency[v].add(u)
        edges.append((u, v))

    queries = []
    answer_count = 0
    for _ in range(q):
        if cursor >= len(values):
            return None
        kind = values[cursor]
        width = 5 if kind == 0 else 4 if kind in (1, 2) else 0
        if width == 0 or cursor + width > len(values):
            return None
        query = tuple(values[cursor : cursor + width])
        cursor += width
        if kind == 0:
            _, u, v, w, x = query
            if not (0 <= u < n and 0 <= v < n and 0 <= w < n and 0 <= x < n) or u == v or w == x:
                return None
        elif kind == 1:
            _, vertex, multiplier, addend = query
            if not 0 <= vertex < n or not 1 <= multiplier < MODULUS or not 0 <= addend < MODULUS:
                return None
        else:
            _, u, v, x = query
            if not 0 <= u < n or not 0 <= v < n or not 0 <= x < MODULUS:
                return None
            answer_count += 1
        queries.append(query)
    if cursor != len(values):
        return None

    # Check the task's tree-preservation promise before output validation.
    check_adjacency = [set(neighbors) for neighbors in adjacency]
    for query in queries:
        if query[0] != 0:
            continue
        _, u, v, w, x = query
        if v not in check_adjacency[u]:
            return None
        check_adjacency[u].remove(v)
        check_adjacency[v].remove(u)
        if _reachable(check_adjacency, w, x):
            return None
        check_adjacency[w].add(x)
        check_adjacency[x].add(w)
    return n, q, affine_values, edges, queries, answer_count


def expected_output(
    values: Sequence[int] | None,
    output_capacity: int | None = None,
    output_is_null: bool = False,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> tuple[int, bytes]:
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or output_capacity is not None and (type(output_capacity) is not int or output_capacity < 0)):
        return INVALID, b""
    parsed = _parse(values, input_is_null, input_length)
    if parsed is None:
        return INVALID, b""
    n, _q, affine_values, edges, queries, answer_count = parsed
    required = 8 * answer_count
    if output_is_null or output_capacity is not None and output_capacity < required:
        return OUTPUT_ERROR, b""

    tree = _LinkCutTree(affine_values)
    for u, v in edges:
        if not tree.link(u, v):
            return INVALID, b""
    answers = []
    for query in queries:
        if query[0] == 0:
            _, u, v, w, x = query
            if not tree.cut(u, v) or not tree.link(w, x):
                return INVALID, b""
        elif query[0] == 1:
            _, vertex, multiplier, addend = query
            tree.set_value(vertex, (multiplier, addend))
        else:
            _, u, v, x = query
            affine = tree.path(u, v)
            if affine is None:
                return INVALID, b""
            answers.append((affine[0] * x + affine[1]) % MODULUS)
    payload = b"".join(struct.pack("<q", answer) for answer in answers)
    return len(payload), payload
