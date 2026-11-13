"""Primary sparse segment-tree oracle for merge, interval split, and queries."""

from __future__ import annotations

import struct
from collections.abc import Sequence

DOMAIN = 64
MAX_Q = 32
MAX_TOTAL_COUNT = MAX_Q * 10
MAX_ROOTS = MAX_Q + 1
MAX_NODES = 1024
MAX_VALID_INPUT_LENGTH = 2 + 4 * MAX_Q
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_OUTPUT_BYTES = 8 * MAX_Q
MAX_WORKSPACE_BYTES = MAX_OUTPUT_BYTES
MAX_INTERNAL_NODE_POOL_BYTES = 16_516
MAX_OPERATION_BUFFER_BYTES = MAX_Q * 4 * 8
MAX_DECLARED_FIXED_ARRAY_BYTES = (
    MAX_INTERNAL_NODE_POOL_BYTES + MAX_OPERATION_BUFFER_BYTES + MAX_WORKSPACE_BYTES
)
INVALID_RESULT = -1
OUTPUT_ERROR = -2


def _parse(values: Sequence[int] | None, input_is_null: bool,
           input_length: int | None):
    if (input_is_null or not isinstance(values, (list, tuple))
            or len(values) < 2 or len(values) > MAX_PARSEABLE_INPUT_LENGTH
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return None
    if input_length is not None and (type(input_length) is not int
                                     or input_length != len(values)
                                     or not 0 <= input_length <= MAX_PARSEABLE_INPUT_LENGTH):
        return None
    domain, q = values[:2]
    if domain != DOMAIN or not 0 <= q <= MAX_Q or len(values) != 2 + 4 * q:
        return None

    root_count = 1
    operations: list[tuple[int, int, int, int]] = []
    for i in range(q):
        op, a, b, c = values[2 + 4 * i: 6 + 4 * i]
        if op == 0:
            if not 0 <= a < root_count or not 1 <= b <= DOMAIN or not 1 <= c <= 10:
                return None
        elif op == 1:
            if not 0 <= a < root_count or not 1 <= b <= c <= DOMAIN or root_count >= MAX_ROOTS:
                return None
            root_count += 1
        elif op == 2:
            if not 0 <= a < root_count or not 0 <= b < root_count or a == b or c != 0:
                return None
        elif op == 3:
            if not 0 <= a < root_count or not 1 <= b <= c <= DOMAIN:
                return None
        elif op == 4:
            if not 0 <= a < root_count or not 1 <= b <= MAX_TOTAL_COUNT or c != 0:
                return None
        else:
            return None
        operations.append((op, a, b, c))
    return operations


class _SparseMultisets:
    def __init__(self) -> None:
        self.left = [0] * MAX_NODES
        self.right = [0] * MAX_NODES
        self.total = [0] * MAX_NODES
        self.next_node = 1

    def new_node(self) -> int:
        if self.next_node >= MAX_NODES:
            raise OverflowError("bounded sparse tree arena exhausted")
        node = self.next_node
        self.next_node += 1
        return node

    def insert(self, node: int, lo: int, hi: int, value: int, amount: int) -> int:
        if node == 0:
            node = self.new_node()
        if lo == hi:
            self.total[node] += amount
            return node
        mid = (lo + hi) // 2
        if value <= mid:
            self.left[node] = self.insert(self.left[node], lo, mid, value, amount)
        else:
            self.right[node] = self.insert(self.right[node], mid + 1, hi, value, amount)
        self.total[node] = self.total[self.left[node]] + self.total[self.right[node]]
        return node

    def merge(self, a: int, b: int, lo: int, hi: int) -> int:
        if a == 0:
            return b
        if b == 0:
            return a
        if lo == hi:
            self.total[a] += self.total[b]
            return a
        mid = (lo + hi) // 2
        self.left[a] = self.merge(self.left[a], self.left[b], lo, mid)
        self.right[a] = self.merge(self.right[a], self.right[b], mid + 1, hi)
        self.total[a] = self.total[self.left[a]] + self.total[self.right[a]]
        return a

    def split(self, node: int, lo: int, hi: int, ql: int, qr: int) -> tuple[int, int]:
        if node == 0 or qr < lo or hi < ql:
            return node, 0
        if ql <= lo and hi <= qr:
            return 0, node
        mid = (lo + hi) // 2
        remain_left, extracted_left = self.split(self.left[node], lo, mid, ql, qr)
        remain_right, extracted_right = self.split(self.right[node], mid + 1, hi, ql, qr)
        self.left[node] = remain_left
        self.right[node] = remain_right
        self.total[node] = self.total[remain_left] + self.total[remain_right]
        extracted = 0
        if extracted_left or extracted_right:
            extracted = self.new_node()
            self.left[extracted] = extracted_left
            self.right[extracted] = extracted_right
            self.total[extracted] = self.total[extracted_left] + self.total[extracted_right]
        return node, extracted

    def range_sum(self, node: int, lo: int, hi: int, ql: int, qr: int) -> int:
        if node == 0 or qr < lo or hi < ql:
            return 0
        if ql <= lo and hi <= qr:
            return self.total[node]
        mid = (lo + hi) // 2
        return (self.range_sum(self.left[node], lo, mid, ql, qr)
                + self.range_sum(self.right[node], mid + 1, hi, ql, qr))

    def kth(self, node: int, lo: int, hi: int, k: int) -> int:
        if node == 0 or k > self.total[node]:
            return -1
        if lo == hi:
            return lo
        mid = (lo + hi) // 2
        left_total = self.total[self.left[node]]
        if k <= left_total:
            return self.kth(self.left[node], lo, mid, k)
        return self.kth(self.right[node], mid + 1, hi, k - left_total)


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if type(output_is_null) is not bool or type(input_is_null) is not bool:
        return INVALID_RESULT, b""
    operations = _parse(values, input_is_null, input_length)
    if operations is None:
        return INVALID_RESULT, b""
    trees = _SparseMultisets()
    roots = [0]
    answers: list[int] = []
    try:
        for op, a, b, c in operations:
            if op == 0:
                roots[a] = trees.insert(roots[a], 1, DOMAIN, b, c)
            elif op == 1:
                roots[a], extracted = trees.split(roots[a], 1, DOMAIN, b, c)
                roots.append(extracted)
            elif op == 2:
                roots[a] = trees.merge(roots[a], roots[b], 1, DOMAIN)
                roots[b] = 0
            elif op == 3:
                answers.append(trees.range_sum(roots[a], 1, DOMAIN, b, c))
            else:
                answers.append(trees.kth(roots[a], 1, DOMAIN, b))
    except OverflowError:
        return INVALID_RESULT, b""
    packed = b"".join(struct.pack("<q", answer) for answer in answers)
    actual_capacity = MAX_OUTPUT_BYTES if capacity is None else capacity
    if (type(actual_capacity) is not int or actual_capacity < 0
            or output_is_null or actual_capacity < len(packed)):
        return OUTPUT_ERROR, b""
    return len(packed), packed
