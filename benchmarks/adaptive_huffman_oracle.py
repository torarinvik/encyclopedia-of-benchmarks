"""Bounded clean-room adaptive-Huffman reference for FGK and Algorithm A."""

from __future__ import annotations

import struct
from dataclasses import dataclass
from collections.abc import Sequence

ALPHABET = 16
MAX_SYMBOLS = 64
MAX_INPUT_LENGTH = 1 + MAX_SYMBOLS
MAX_PARSEABLE_INPUT_LENGTH = MAX_INPUT_LENGTH + 1
MAX_BITS = 1216
MAX_OUTPUT_BYTES = 160
MAX_WORKSPACE_BYTES = 4096
INVALID_RESULT = -1
OUTPUT_ERROR = -2
NYT, LEAF, INTERNAL = 0, 1, 2


@dataclass
class Node:
    parent: int
    left: int
    right: int
    symbol: int
    kind: int
    weight: int = 0


def _parse(values: Sequence[int] | None, input_is_null: bool,
           input_length: int | None) -> tuple[int, ...] | None:
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple))
            or not 1 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
            or any(type(word) is not int or not -(1 << 63) <= word < (1 << 63)
                   for word in values)):
        return None
    if input_length is None:
        input_length = len(values)
    if type(input_length) is not int or input_length != len(values):
        return None
    size = values[0]
    if not 0 <= size <= MAX_SYMBOLS or len(values) != size + 1:
        return None
    symbols = tuple(values[1:])
    if any(not 0 <= symbol < ALPHABET for symbol in symbols):
        return None
    return symbols


def _new_tree() -> tuple[list[Node], int, list[int], list[int]]:
    nodes = [Node(-1, -1, -1, -1, NYT)]
    leaf_of = [-1] * ALPHABET
    order = [0]
    return nodes, 0, leaf_of, order


def _path(nodes: list[Node], root: int, node: int) -> list[int]:
    reversed_path: list[int] = []
    while node != root:
        parent = nodes[node].parent
        reversed_path.append(int(nodes[parent].right == node))
        node = parent
    return list(reversed(reversed_path))


def _is_ancestor(nodes: list[Node], ancestor: int, node: int) -> bool:
    parent = nodes[node].parent
    while parent >= 0:
        if parent == ancestor:
            return True
        parent = nodes[parent].parent
    return False


def _replace_child(nodes: list[Node], parent: int, old: int, new: int) -> None:
    if nodes[parent].left == old:
        nodes[parent].left = new
    elif nodes[parent].right == old:
        nodes[parent].right = new


def _swap_positions(nodes: list[Node], root: int, a: int, b: int,
                    order: list[int] | None) -> int:
    if (a == b or nodes[a].parent == b or nodes[b].parent == a
            or _is_ancestor(nodes, a, b) or _is_ancestor(nodes, b, a)):
        return root
    parent_a, parent_b = nodes[a].parent, nodes[b].parent
    if parent_a == parent_b:
        if parent_a >= 0:
            nodes[parent_a].left, nodes[parent_a].right = (
                nodes[parent_a].right, nodes[parent_a].left)
    else:
        if parent_a >= 0:
            _replace_child(nodes, parent_a, a, b)
        if parent_b >= 0:
            _replace_child(nodes, parent_b, b, a)
        nodes[a].parent, nodes[b].parent = parent_b, parent_a
    if root == a:
        root = b
    elif root == b:
        root = a
    if order is not None:
        ia, ib = order.index(a), order.index(b)
        order[ia], order[ib] = b, a
    return root


def _split_nyt(nodes: list[Node], root: int, nyt: int, leaf_of: list[int],
               symbol: int, has_remaining: bool, order: list[int] | None) -> tuple[int, int, int]:
    if not has_remaining:
        nodes[nyt].kind = LEAF
        nodes[nyt].symbol = symbol
        leaf_of[symbol] = nyt
        return root, -1, nyt
    left = len(nodes)
    right = left + 1
    nodes.extend((Node(nyt, -1, -1, -1, NYT),
                  Node(nyt, -1, -1, symbol, LEAF)))
    nodes[nyt].kind = INTERNAL
    nodes[nyt].left = left
    nodes[nyt].right = right
    leaf_of[symbol] = right
    if order is not None:
        position = order.index(nyt)
        order[position:position + 1] = [left, right, nyt]
    return root, left, right


def _fgk_leader(nodes: list[Node], order: list[int], node: int,
                leaves_only: bool = False) -> int:
    weight = nodes[node].weight
    parent = nodes[node].parent
    for candidate in reversed(order):
        if (candidate == parent or nodes[candidate].weight != weight
                or leaves_only and nodes[candidate].kind == INTERNAL
                or _is_ancestor(nodes, candidate, node)
                or _is_ancestor(nodes, node, candidate)):
            continue
        return candidate
    return node


def _update_fgk(nodes: list[Node], root: int, nyt: int, order: list[int],
                node: int) -> int:
    parent = nodes[node].parent
    if nyt >= 0 and parent >= 0 and nodes[nyt].parent == parent:
        leader = _fgk_leader(nodes, order, node, leaves_only=True)
        root = _swap_positions(nodes, root, node, leader, order)
        nodes[node].weight += 1
        node = nodes[node].parent
    while node != root:
        leader = _fgk_leader(nodes, order, node)
        root = _swap_positions(nodes, root, node, leader, order)
        nodes[node].weight += 1
        node = nodes[node].parent
    nodes[root].weight += 1
    return root


def _implicit_order(nodes: list[Node], root: int) -> list[int]:
    records: list[tuple[int, int, int]] = []
    for node_id in range(len(nodes)):
        reverse_path: list[int] = []
        at = node_id
        while at != root:
            parent = nodes[at].parent
            reverse_path.append(int(nodes[parent].right == at))
            at = parent
        path = 0
        for bit in reversed(reverse_path):
            path = 2 * path + bit
        records.append((-len(reverse_path), path, node_id))
    records.sort()
    return [node_id for _, _, node_id in records]


def _vitter_leader(nodes: list[Node], root: int, node: int) -> int:
    for candidate in reversed(_implicit_order(nodes, root)):
        if (nodes[candidate].weight == nodes[node].weight
                and nodes[candidate].kind == nodes[node].kind):
            return candidate
    return node


def _slide_increment(nodes: list[Node], root: int, node: int) -> tuple[int, int]:
    old_parent = nodes[node].parent
    target_kind = INTERNAL if nodes[node].kind == LEAF else LEAF
    target_weight = nodes[node].weight + (nodes[node].kind == INTERNAL)
    block = [candidate for candidate in _implicit_order(nodes, root)
             if nodes[candidate].kind == target_kind
             and nodes[candidate].weight == target_weight]
    for candidate in block:
        root = _swap_positions(nodes, root, node, candidate, None)
    nodes[node].weight += 1
    following = nodes[node].parent if nodes[node].kind == LEAF else old_parent
    return root, following


def _update_vitter(nodes: list[Node], root: int, nyt: int, node: int,
                   just_split: bool) -> int:
    leaf_to_increment = -1
    if just_split:
        leaf_to_increment = node
        node = nodes[node].parent
    else:
        leader = _vitter_leader(nodes, root, node)
        root = _swap_positions(nodes, root, node, leader, None)
        parent = nodes[node].parent
        if nyt >= 0 and parent >= 0 and nodes[nyt].parent == parent:
            leaf_to_increment = node
            node = parent
    while node != root:
        root, node = _slide_increment(nodes, root, node)
    if leaf_to_increment >= 0:
        root, _ = _slide_increment(nodes, root, leaf_to_increment)
    nodes[root].weight += 1
    return root


def _encode(symbols: Sequence[int], algorithm: str) -> bytes:
    nodes, root, leaf_of, order = _new_tree()
    nyt = 0
    seen = 0
    bits: list[int] = []
    for symbol in symbols:
        is_new = leaf_of[symbol] < 0
        current = nyt if is_new else leaf_of[symbol]
        bits.extend(_path(nodes, root, current))
        if is_new:
            bits.extend((symbol >> shift) & 1 for shift in (3, 2, 1, 0))
            seen += 1
            just_split = seen < ALPHABET
            root, nyt, current = _split_nyt(nodes, root, nyt, leaf_of, symbol,
                                            just_split, order if algorithm == "fgk" else None)
        else:
            just_split = False
        if algorithm == "fgk":
            root = _update_fgk(nodes, root, nyt, order, current)
        else:
            root = _update_vitter(nodes, root, nyt, current, just_split)
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
    payload = _encode(symbols, algorithm)
    if output_is_null or capacity is not None and (
            type(capacity) is not int or capacity < len(payload)):
        return OUTPUT_ERROR, b""
    return len(payload), payload
