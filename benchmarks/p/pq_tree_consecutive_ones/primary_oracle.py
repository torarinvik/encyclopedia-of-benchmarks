"""Clean-room bounded PQ-tree reductions and canonical family encoding."""

from __future__ import annotations

import struct

MAX_N = 20
MAX_M = 32
MAX_VALID_INPUT_LENGTH = 2 + MAX_M
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_REDUCED_NODES = 2 * MAX_N - 1
MAX_NODES = 128
MAX_OUTPUT_BYTES = 648
WORKSPACE_BYTES = 16_384

WHITE, BLACK, MIXED = 0, 1, 2
LEAF, P_NODE, Q_NODE = 0, 1, 2


class _NoReduction(Exception):
    pass


class _Tree:
    def __init__(self, n: int):
        self.n = n
        self.kind = [LEAF] * MAX_NODES
        self.argument = [0] * MAX_NODES
        self.children: list[list[int]] = [[] for _ in range(MAX_NODES)]
        self.color = [WHITE] * MAX_NODES
        self.free: list[int] = []
        self.next_id = n + 1
        for leaf in range(n):
            self.argument[leaf] = leaf
        self.root = n
        self.kind[self.root] = P_NODE
        self.children[self.root] = list(range(n))

    def new_node(self, kind: int) -> int:
        if self.free:
            node = self.free.pop()
        else:
            if self.next_id >= MAX_NODES:
                raise _NoReduction("bounded PQ-tree node arena exhausted")
            node = self.next_id
            self.next_id += 1
        self.kind[node] = kind
        self.argument[node] = 0
        self.children[node] = []
        self.color[node] = WHITE
        return node

    def delete_node(self, node: int) -> None:
        self.children[node] = []
        self.free.append(node)

    def paint(self, node: int, mask: int) -> int:
        if self.kind[node] == LEAF:
            self.color[node] = BLACK if (mask >> self.argument[node]) & 1 else WHITE
            return self.color[node]
        saw_white = saw_black = False
        for child in self.children[node]:
            shade = self.paint(child, mask)
            saw_white |= shade != BLACK
            saw_black |= shade != WHITE
        self.color[node] = MIXED if saw_white and saw_black else BLACK if saw_black else WHITE
        return self.color[node]

    def _q_pattern(self, children: list[int]) -> bool:
        mixed = [i for i, child in enumerate(children) if self.color[child] == MIXED]
        if len(mixed) > 1:
            return False
        if mixed:
            pivot = mixed[0]
        else:
            pivot = next((i for i, child in enumerate(children)
                          if self.color[child] == BLACK), -1)
        if pivot < 0:
            return False
        return (all(self.color[child] == WHITE for child in children[:pivot])
                and all(self.color[child] == BLACK for child in children[pivot + 1:]))

    def split(self, node: int) -> list[int]:
        if self.color[node] != MIXED:
            return [node]
        children = list(self.children[node])
        if self.kind[node] == Q_NODE:
            if not self._q_pattern(children):
                children.reverse()
                if not self._q_pattern(children):
                    raise _NoReduction("Q-node colors cannot form one interval")
            result: list[int] = []
            for child in children:
                if self.color[child] == MIXED:
                    result.extend(self.split(child))
                else:
                    result.append(child)
            self.delete_node(node)
            return result

        white = [child for child in children if self.color[child] == WHITE]
        black = [child for child in children if self.color[child] == BLACK]
        mixed = [child for child in children if self.color[child] == MIXED]
        if len(mixed) > 1:
            raise _NoReduction("P-node has multiple mixed children")
        result = []
        if white:
            group = self.new_node(P_NODE)
            self.children[group] = white
            result.append(group)
        if mixed:
            result.extend(self.split(mixed[0]))
        if black:
            group = self.new_node(P_NODE)
            self.children[group] = black
            result.append(group)
        self.delete_node(node)
        return result

    def reduce_at(self, node: int) -> None:
        if self.color[node] != MIXED:
            return
        if self.kind[node] == P_NODE:
            children = list(self.children[node])
            white = [child for child in children if self.color[child] == WHITE]
            black = [child for child in children if self.color[child] == BLACK]
            mixed = [child for child in children if self.color[child] == MIXED]
            if not black and len(mixed) == 1:
                self.reduce_at(mixed[0])
                return
            if len(mixed) > 2:
                raise _NoReduction("P-node has more than two mixed children")

            q_node = self.new_node(Q_NODE)
            outer = list(white)
            outer.append(q_node)
            q_children: list[int] = []
            if mixed:
                q_children.extend(self.split(mixed[0]))
            if black:
                black_group = self.new_node(P_NODE)
                self.children[black_group] = black
                q_children.append(black_group)
            if len(mixed) == 2:
                q_children.extend(reversed(self.split(mixed[1])))
            self.children[q_node] = q_children
            self.children[node] = outer
            return

        children = list(self.children[node])
        nonwhite = [i for i, child in enumerate(children) if self.color[child] != WHITE]
        if not nonwhite:
            raise _NoReduction("mixed Q-node has no selected child")
        left, right = nonwhite[0], nonwhite[-1]
        if any(self.color[children[i]] != BLACK for i in range(left + 1, right)):
            raise _NoReduction("Q-node has a gap inside the selected interval")
        if left == right and self.color[children[left]] == MIXED:
            self.reduce_at(children[left])
            return
        result = children[:left]
        result.extend(self.split(children[left]))
        result.extend(children[left + 1:right])
        if right != left:
            result.extend(reversed(self.split(children[right])))
        result.extend(children[right + 1:])
        self.children[node] = result

    def normalize(self, node: int) -> int:
        if self.kind[node] == LEAF:
            return node
        normalized = [self.normalize(child) for child in self.children[node]]
        self.children[node] = normalized
        if len(normalized) == 1:
            child = normalized[0]
            self.delete_node(node)
            return child
        if self.kind[node] == Q_NODE and len(normalized) == 2:
            self.kind[node] = P_NODE
        return node

    def reduce(self, mask: int) -> None:
        self.paint(self.root, mask)
        self.reduce_at(self.root)
        self.root = self.normalize(self.root)

    def compare_nodes(self, left: int, right: int) -> int:
        left_key = (self.kind[left], self.argument[left] if self.kind[left] == LEAF
                    else len(self.children[left]))
        right_key = (self.kind[right], self.argument[right] if self.kind[right] == LEAF
                     else len(self.children[right]))
        if left_key != right_key:
            return -1 if left_key < right_key else 1
        if self.kind[left] == LEAF:
            return 0
        a, b = self.children[left], self.children[right]
        for child_a, child_b in zip(a, b):
            comparison = self.compare_nodes(child_a, child_b)
            if comparison:
                return comparison
        return (len(a) > len(b)) - (len(a) < len(b))

    def canonicalize(self, node: int) -> None:
        if self.kind[node] == LEAF:
            return
        for child in self.children[node]:
            self.canonicalize(child)
        children = self.children[node]
        if self.kind[node] == P_NODE:
            for i in range(1, len(children)):
                current = children[i]
                j = i
                while j > 0 and self.compare_nodes(current, children[j - 1]) < 0:
                    children[j] = children[j - 1]
                    j -= 1
                children[j] = current
        elif len(children) > 1:
            reversed_children = list(reversed(children))
            comparison = 0
            for a, b in zip(children, reversed_children):
                comparison = self.compare_nodes(a, b)
                if comparison:
                    break
            if comparison > 0:
                self.children[node] = reversed_children

    def frontier_count(self, node: int) -> int:
        if self.kind[node] == LEAF:
            return 1
        product = 1
        for child in self.children[node]:
            product *= self.frontier_count(child)
        if self.kind[node] == P_NODE:
            for factor in range(2, len(self.children[node]) + 1):
                product *= factor
        else:
            product *= 2
        return product

    def serialize(self, node: int, words: list[int]) -> None:
        words.extend((self.kind[node], self.argument[node] if self.kind[node] == LEAF
                      else len(self.children[node])))
        for child in self.children[node]:
            self.serialize(child, words)

    def node_count(self, node: int) -> int:
        return 1 + sum(self.node_count(child) for child in self.children[node])


def _parse(values: list[int] | tuple[int, ...] | None, input_is_null: bool,
           input_length: int | None):
    if input_is_null or not isinstance(values, (list, tuple)):
        return None
    if (any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
            for value in values)
            or input_length is not None and
            (type(input_length) is not int or input_length != len(values))
            or len(values) < 2 or len(values) > MAX_PARSEABLE_INPUT_LENGTH):
        return None
    n, row_count = values[0], values[1]
    if not 2 <= n <= MAX_N or not 0 <= row_count <= MAX_M:
        return None
    if len(values) != 2 + row_count:
        return None
    limit = (1 << n) - 1
    if any(mask < 0 or mask > limit for mask in values[2:]):
        return None
    return n, values[2:]


def evaluate(values: list[int] | tuple[int, ...] | None, *, input_is_null: bool = False,
             input_length: int | None = None) -> tuple[int, bytes]:
    parsed = _parse(values, input_is_null, input_length)
    if parsed is None:
        return -1, b""
    n, masks = parsed
    try:
        tree = _Tree(n)
        for mask in masks:
            tree.reduce(mask)
    except _NoReduction:
        words = [0, 0, 0]
        return 24, struct.pack("<3q", *words)
    tree.canonicalize(tree.root)
    words = [1, tree.frontier_count(tree.root), tree.node_count(tree.root)]
    tree.serialize(tree.root, words)
    payload = b"".join(struct.pack("<q", word) for word in words)
    if len(payload) > MAX_OUTPUT_BYTES:
        raise AssertionError("canonical PQ-tree exceeded its proven output bound")
    return len(payload), payload


def expected_output(values: list[int] | tuple[int, ...] | None,
                    capacity: int | None = MAX_OUTPUT_BYTES,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if (type(input_is_null) is not bool or type(output_is_null) is not bool
            or capacity is not None and (type(capacity) is not int or capacity < 0)):
        return -1, b""
    result, payload = evaluate(values, input_is_null=input_is_null,
                               input_length=input_length)
    if result < 0:
        return result, payload
    if output_is_null or capacity is not None and capacity < result:
        return -2, b""
    return result, payload
