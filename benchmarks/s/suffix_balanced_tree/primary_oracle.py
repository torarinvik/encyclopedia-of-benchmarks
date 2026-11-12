"""Scapegoat-style successor-tag suffix-tree reference implementation."""

from __future__ import annotations

from collections.abc import Sequence
import struct

MAX_TEXT = 32
MAX_INPUT = 33
MAX_OUTPUT_BYTES = 256
TAG_LIMIT = 1 << 62
INVALID = -1
OUTPUT_ERROR = -2
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1


def parse_input(values: Sequence[int] | None, input_is_null: bool = False,
                input_length: int | None = None):
    if input_is_null or not isinstance(values, (list, tuple)) or not 1 <= len(values) <= MAX_INPUT:
        return None
    if input_length is not None and (type(input_length) is not int or input_length != len(values)):
        return None
    if any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values):
        return None
    n = values[0]
    if not 0 <= n <= MAX_TEXT or len(values) != 1 + n:
        return None
    text = list(values[1:])
    if any(not 0 <= code <= 255 for code in text):
        return None
    return text


class _ScapegoatSuffixTree:
    def __init__(self, text: list[int]):
        self.text = text
        self.n = len(text)
        self.left = [-1] * self.n
        self.right = [-1] * self.n
        self.size = [0] * self.n
        self.tag = [0] * self.n
        self.root = -1

    def _less(self, x: int, y: int) -> bool:
        if self.text[x] != self.text[y]:
            return self.text[x] < self.text[y]
        tag_x = self.tag[x + 1] if x + 1 < self.n else 0
        tag_y = self.tag[y + 1] if y + 1 < self.n else 0
        return tag_x < tag_y

    def _node_size(self, node: int) -> int:
        return 0 if node < 0 else self.size[node]

    def _flatten(self, node: int, result: list[int]) -> None:
        if node < 0:
            return
        self._flatten(self.left[node], result)
        result.append(node)
        self._flatten(self.right[node], result)

    def _build(self, nodes: list[int], lo: int, hi: int, low: int, high: int) -> int:
        if lo >= hi:
            return -1
        mid = lo + (hi - lo) // 2
        root = nodes[mid]
        tag = low + (high - low) // 2
        self.tag[root] = tag
        self.left[root] = self._build(nodes, lo, mid, low, tag)
        self.right[root] = self._build(nodes, mid + 1, hi, tag, high)
        self.size[root] = 1 + self._node_size(self.left[root]) + self._node_size(self.right[root])
        return root

    def _rebuild(self, root: int, low: int, high: int) -> int:
        nodes: list[int] = []
        self._flatten(root, nodes)
        return self._build(nodes, 0, len(nodes), low, high)

    def _insert(self, root: int, pos: int, low: int, high: int) -> int:
        if root < 0:
            self.left[pos] = self.right[pos] = -1
            self.size[pos] = 1
            self.tag[pos] = low + (high - low) // 2
            return pos
        middle = self.tag[root]
        if self._less(pos, root):
            self.left[root] = self._insert(self.left[root], pos, low, middle)
        else:
            self.right[root] = self._insert(self.right[root], pos, middle, high)
        left_size = self._node_size(self.left[root])
        right_size = self._node_size(self.right[root])
        self.size[root] = 1 + left_size + right_size
        if 4 * max(left_size, right_size) >= 3 * self.size[root]:
            return self._rebuild(root, low, high)
        return root

    def suffix_array(self) -> list[int]:
        for pos in range(self.n - 1, -1, -1):
            self.root = self._insert(self.root, pos, 0, TAG_LIMIT)
        result: list[int] = []
        self._flatten(self.root, result)
        return result


def expected_output(values: Sequence[int] | None, output_capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or output_capacity is not None and (type(output_capacity) is not int or output_capacity < 0)):
        return INVALID, b""
    text = parse_input(values, input_is_null, input_length)
    if text is None:
        return INVALID, b""
    required = 8 * len(text)
    if output_is_null or output_capacity is not None and output_capacity < required:
        return OUTPUT_ERROR, b""
    suffixes = _ScapegoatSuffixTree(text).suffix_array()
    payload = b"".join(struct.pack("<q", suffix) for suffix in suffixes)
    return len(payload), payload
