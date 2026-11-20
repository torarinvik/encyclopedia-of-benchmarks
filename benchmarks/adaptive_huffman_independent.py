"""Object-tree reference for bounded adaptive Huffman profiles."""

from __future__ import annotations

import struct
from dataclasses import dataclass
from collections.abc import Sequence

ALPHABET = 16
MAX_SYMBOLS = 64
INVALID_RESULT = -1
OUTPUT_ERROR = -2
NYT, LEAF, INTERNAL = 0, 1, 2


@dataclass(eq=False)
class TreeNode:
    kind: int
    symbol: int = -1
    weight: int = 0
    parent: TreeNode | None = None
    left: TreeNode | None = None
    right: TreeNode | None = None


def _parse(values: Sequence[int] | None, input_is_null: bool,
           input_length: int | None) -> tuple[int, ...] | None:
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple))
            or not 1 <= len(values) <= MAX_SYMBOLS + 2
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return None
    if input_length is None:
        input_length = len(values)
    if type(input_length) is not int or input_length != len(values):
        return None
    size = values[0]
    if not 0 <= size <= MAX_SYMBOLS or len(values) != size + 1:
        return None
    symbols = tuple(values[1:])
    if any(symbol < 0 or symbol >= ALPHABET for symbol in symbols):
        return None
    return symbols


def _path(root: TreeNode, target: TreeNode) -> list[int]:
    def search(node: TreeNode, prefix: list[int]) -> list[int] | None:
        if node is target:
            return prefix
        if node.left is not None:
            found = search(node.left, prefix + [0])
            if found is not None:
                return found
        if node.right is not None:
            return search(node.right, prefix + [1])
        return None
    result = search(root, [])
    assert result is not None
    return result


def _ancestor(ancestor: TreeNode, node: TreeNode) -> bool:
    at = node.parent
    while at is not None:
        if at is ancestor:
            return True
        at = at.parent
    return False


def _swap(root: TreeNode, a: TreeNode, b: TreeNode) -> TreeNode:
    if a is b or a.parent is b or b.parent is a or _ancestor(a, b) or _ancestor(b, a):
        return root
    pa, pb = a.parent, b.parent
    if pa is pb:
        if pa is not None:
            pa.left, pa.right = pa.right, pa.left
    else:
        if pa is not None:
            if pa.left is a: pa.left = b
            elif pa.right is a: pa.right = b
        if pb is not None:
            if pb.left is b: pb.left = a
            elif pb.right is b: pb.right = a
        a.parent, b.parent = pb, pa
    if root is a: return b
    if root is b: return a
    return root


def _depth_key(root: TreeNode, target: TreeNode) -> tuple[int, int]:
    path = _path(root, target)
    code = 0
    for bit in path: code = code * 2 + bit
    return -len(path), code


def _implicit_order(root: TreeNode, nodes: list[TreeNode]) -> list[TreeNode]:
    return sorted(nodes, key=lambda node: _depth_key(root, node))


def _simulate(symbols: Sequence[int], method: str) -> bytes:
    root = TreeNode(NYT)
    nyt: TreeNode | None = root
    leaves: list[TreeNode | None] = [None] * ALPHABET
    nodes = [root]
    fgk_order = [root]
    seen = 0
    bits: list[int] = []

    for symbol in symbols:
        is_new = leaves[symbol] is None
        current = nyt if is_new else leaves[symbol]
        assert current is not None
        bits.extend(_path(root, current))
        if is_new:
            bits.extend((symbol >> shift) & 1 for shift in (3, 2, 1, 0))
            seen += 1
            if seen < ALPHABET:
                left, right = TreeNode(NYT), TreeNode(LEAF, symbol)
                left.parent = right.parent = current
                current.kind = INTERNAL
                current.left, current.right = left, right
                nodes.extend((left, right))
                leaves[symbol] = right
                nyt = left
                if method == "fgk":
                    index = fgk_order.index(current)
                    fgk_order[index:index+1] = [left, right, current]
                just_split = True
                current = right
            else:
                current.kind = LEAF
                current.symbol = symbol
                leaves[symbol] = current
                nyt = None
                just_split = False
        else:
            just_split = False

        if method == "fgk":
            parent = current.parent
            if nyt is not None and parent is not None and nyt.parent is parent:
                leader = current
                for candidate in reversed(fgk_order):
                    if (candidate.kind != INTERNAL and candidate.weight == current.weight
                            and candidate is not parent and not _ancestor(candidate, current)
                            and not _ancestor(current, candidate)):
                        leader = candidate
                        break
                root = _swap(root, current, leader)
                fgk_order[fgk_order.index(current)], fgk_order[fgk_order.index(leader)] = leader, current
                current.weight += 1
                current = current.parent
            while current is not root:
                leader = current
                parent = current.parent
                for candidate in reversed(fgk_order):
                    if (candidate.weight == current.weight and candidate is not parent
                            and not _ancestor(candidate, current)
                            and not _ancestor(current, candidate)):
                        leader = candidate
                        break
                root = _swap(root, current, leader)
                fgk_order[fgk_order.index(current)], fgk_order[fgk_order.index(leader)] = leader, current
                current.weight += 1
                current = current.parent
            root.weight += 1
            continue

        leaf_to_increment: TreeNode | None = None
        if just_split:
            leaf_to_increment = current
            current = current.parent
        else:
            ordered = _implicit_order(root, nodes)
            leader = current
            for candidate in reversed(ordered):
                if candidate.weight == current.weight and candidate.kind == current.kind:
                    leader = candidate
                    break
            root = _swap(root, current, leader)
            parent = current.parent
            if nyt is not None and parent is not None and nyt.parent is parent:
                leaf_to_increment = current
                current = parent

        def slide_and_increment(node: TreeNode) -> TreeNode | None:
            nonlocal root
            old_parent = node.parent
            kind = INTERNAL if node.kind == LEAF else LEAF
            weight = node.weight + (node.kind == INTERNAL)
            block = [candidate for candidate in _implicit_order(root, nodes)
                     if candidate.kind == kind and candidate.weight == weight]
            for candidate in block:
                root = _swap(root, node, candidate)
            node.weight += 1
            return node.parent if node.kind == LEAF else old_parent

        while current is not root:
            next_node = slide_and_increment(current)
            assert next_node is not None
            current = next_node
        if leaf_to_increment is not None:
            slide_and_increment(leaf_to_increment)
        root.weight += 1

    packed = bytearray((len(bits) + 7) // 8)
    for i, bit in enumerate(bits):
        if bit:
            packed[i // 8] |= 1 << (7 - i % 8)
    return struct.pack("<Q", len(bits)) + bytes(packed)


def expected_output(values: Sequence[int] | None, algorithm: str,
                    capacity: int | None = None, output_is_null: bool = False,
                    input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if (algorithm not in ("fgk", "vitter") or type(output_is_null) is not bool
            or type(input_is_null) is not bool):
        return INVALID_RESULT, b""
    symbols = _parse(values, input_is_null, input_length)
    if symbols is None:
        return INVALID_RESULT, b""
    payload = _simulate(symbols, algorithm)
    if output_is_null or capacity is not None and (
            type(capacity) is not int or capacity < len(payload)):
        return OUTPUT_ERROR, b""
    return len(payload), payload
