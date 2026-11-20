"""Primary bounded ternary-search-trie oracle for the local profile."""

from __future__ import annotations

from dataclasses import dataclass
from typing import Sequence

MAX_OPERATIONS = 64
MAX_KEY_LENGTH = 6
RECORD_WIDTH = MAX_KEY_LENGTH + 3
MAX_INPUT_VALUES = 1 + MAX_OPERATIONS * RECORD_WIDTH
MAX_PARSEABLE_INPUT_VALUES = MAX_INPUT_VALUES + 1
MAX_NODES = MAX_OPERATIONS * MAX_KEY_LENGTH
MAX_VALUE = 65_535


@dataclass
class Node:
    char: int
    left: int = 0
    middle: int = 0
    right: int = 0
    value: int = 0
    present: bool = False


class TernarySearchTrie:
    def __init__(self) -> None:
        self.nodes: list[Node | None] = [None]
        self.root = 0
        self.size = 0

    def _new(self, char: int) -> int:
        if len(self.nodes) > MAX_NODES:
            raise ValueError("node bound exceeded")
        self.nodes.append(Node(char))
        return len(self.nodes) - 1

    def _put(self, node_id: int, key: tuple[int, ...], depth: int, value: int) -> tuple[int, int]:
        if node_id == 0:
            node_id = self._new(key[depth])
        node = self.nodes[node_id]
        assert node is not None
        if key[depth] < node.char:
            node.left, old = self._put(node.left, key, depth, value)
            return node_id, old
        if key[depth] > node.char:
            node.right, old = self._put(node.right, key, depth, value)
            return node_id, old
        if depth + 1 < len(key):
            node.middle, old = self._put(node.middle, key, depth + 1, value)
            return node_id, old
        old = node.value if node.present else 0
        if not node.present:
            self.size += 1
        node.value = value
        node.present = True
        return node_id, old

    def put(self, key: tuple[int, ...], value: int) -> int:
        self.root, old = self._put(self.root, key, 0, value)
        return old

    def _find(self, key: tuple[int, ...]) -> int:
        node_id = self.root
        depth = 0
        while node_id:
            node = self.nodes[node_id]
            assert node is not None
            char = key[depth]
            if char < node.char:
                node_id = node.left
            elif char > node.char:
                node_id = node.right
            elif depth + 1 == len(key):
                return node_id
            else:
                node_id = node.middle
                depth += 1
        return 0

    def get(self, key: tuple[int, ...]) -> int:
        node_id = self._find(key)
        if not node_id:
            return 0
        node = self.nodes[node_id]
        assert node is not None
        return node.value if node.present else 0

    def _delete(self, node_id: int, key: tuple[int, ...], depth: int) -> tuple[int, int]:
        if not node_id:
            return 0, 0
        node = self.nodes[node_id]
        assert node is not None
        if key[depth] < node.char:
            node.left, removed = self._delete(node.left, key, depth)
        elif key[depth] > node.char:
            node.right, removed = self._delete(node.right, key, depth)
        elif depth + 1 < len(key):
            node.middle, removed = self._delete(node.middle, key, depth + 1)
        elif node.present:
            removed = node.value
            node.value = 0
            node.present = False
            self.size -= 1
        else:
            removed = 0
        if not node.present and not node.left and not node.middle and not node.right:
            return 0, removed
        return node_id, removed

    def delete(self, key: tuple[int, ...]) -> int:
        self.root, removed = self._delete(self.root, key, 0)
        return removed

    def longest_prefix(self, query: tuple[int, ...]) -> int:
        node_id = self.root
        depth = 0
        best = 0
        while node_id and depth < len(query):
            node = self.nodes[node_id]
            assert node is not None
            char = query[depth]
            if char < node.char:
                node_id = node.left
            elif char > node.char:
                node_id = node.right
            else:
                depth += 1
                if node.present:
                    best = depth
                node_id = node.middle
        return best

    def _count_subtree(self, node_id: int) -> int:
        if not node_id:
            return 0
        node = self.nodes[node_id]
        assert node is not None
        return int(node.present) + self._count_subtree(node.left) + self._count_subtree(node.middle) + self._count_subtree(node.right)

    def prefix_count(self, prefix: tuple[int, ...]) -> int:
        if not prefix:
            return self.size
        node_id = self.root
        depth = 0
        while node_id:
            node = self.nodes[node_id]
            assert node is not None
            char = prefix[depth]
            if char < node.char:
                node_id = node.left
            elif char > node.char:
                node_id = node.right
            elif depth + 1 == len(prefix):
                return int(node.present) + self._count_subtree(node.middle)
            else:
                node_id = node.middle
                depth += 1
        return 0

    def match_count(self, pattern: tuple[int, ...]) -> int:
        def visit(node_id: int, depth: int) -> int:
            if not node_id:
                return 0
            node = self.nodes[node_id]
            assert node is not None
            token = pattern[depth]
            if token == ord("."):
                matched = int(node.present) if depth + 1 == len(pattern) else visit(node.middle, depth + 1)
                return visit(node.left, depth) + matched + visit(node.right, depth)
            if token < node.char:
                return visit(node.left, depth)
            if token > node.char:
                return visit(node.right, depth)
            if depth + 1 == len(pattern):
                return int(node.present)
            return visit(node.middle, depth + 1)

        return visit(self.root, 0) if pattern else 0


def _parse(values: Sequence[int]) -> list[tuple[int, tuple[int, ...], int]]:
    if len(values) < 1 or len(values) > MAX_PARSEABLE_INPUT_VALUES:
        raise ValueError("input length")
    count = values[0]
    if not isinstance(count, int) or count < 0 or count > MAX_OPERATIONS:
        raise ValueError("operation count")
    if len(values) != 1 + count * RECORD_WIDTH:
        raise ValueError("frame length")
    parsed: list[tuple[int, tuple[int, ...], int]] = []
    offset = 1
    for _ in range(count):
        record = values[offset : offset + RECORD_WIDTH]
        offset += RECORD_WIDTH
        opcode, key_length = record[0], record[1]
        if not isinstance(opcode, int) or opcode < 0 or opcode > 6:
            raise ValueError("opcode")
        if not isinstance(key_length, int) or key_length < 0 or key_length > MAX_KEY_LENGTH:
            raise ValueError("key length")
        if opcode in (0, 1, 2) and key_length == 0:
            raise ValueError("empty key")
        if opcode == 6 and key_length != 0:
            raise ValueError("size key length")
        key_codes = record[2 : 2 + key_length]
        padding = record[2 + key_length : 2 + MAX_KEY_LENGTH]
        if any(not isinstance(code, int) or not (97 <= code <= 122 or opcode == 5 and code == 46) for code in key_codes):
            raise ValueError("character")
        if any(code != 0 for code in padding):
            raise ValueError("padding")
        value = record[-1]
        if opcode == 0:
            if not isinstance(value, int) or value < 1 or value > MAX_VALUE:
                raise ValueError("value")
        elif value != 0:
            raise ValueError("unused value")
        parsed.append((opcode, tuple(key_codes), value))
    return parsed


def run(values: Sequence[int] | None) -> int:
    if values is None:
        return -1
    try:
        operations = _parse(values)
        trie = TernarySearchTrie()
        total = 0
        for index, (opcode, key, value) in enumerate(operations, start=1):
            if opcode == 0:
                observed = trie.put(key, value)
            elif opcode == 1:
                observed = trie.get(key)
            elif opcode == 2:
                observed = trie.delete(key)
            elif opcode == 3:
                observed = trie.longest_prefix(key)
            elif opcode == 4:
                observed = trie.prefix_count(key)
            elif opcode == 5:
                observed = trie.match_count(key)
            else:
                observed = trie.size
            total += index * observed
        return total
    except (ValueError, IndexError, RecursionError):
        return -1


def expected_result(
    values: Sequence[int] | None,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> int:
    if input_is_null or values is None:
        return -1
    if input_length is None:
        input_length = len(values)
    if input_length < 0 or input_length > len(values) or input_length > MAX_PARSEABLE_INPUT_VALUES:
        return -1
    return run(values[:input_length])
