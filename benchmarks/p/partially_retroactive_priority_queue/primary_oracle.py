"""Bounded segment-tree reference for the retroactive priority-queue trace."""

from __future__ import annotations

import struct

MAX_N = 64
MAX_Q = 64
MAX_INPUT_LENGTH = 322
MAX_PARSEABLE_INPUT_LENGTH = 323
MAX_OUTPUT_BYTES = 1024
MAX_WORKSPACE_BYTES = 16384
INVALID_RESULT = -1
OUTPUT_ERROR = -2


class _Tree:
    __slots__ = ("n", "base", "types", "values", "sum", "pmin", "smax", "minadd", "maxdel", "count", "total")

    def __init__(self, n: int) -> None:
        self.n = n
        self.base = 1
        while self.base < n + 1:
            self.base <<= 1
        size = self.base * 2
        self.types = [2] * (n + 1)
        self.values = [-1] * (n + 1)
        self.sum = [0] * size
        self.pmin = [0] * size
        self.smax = [0] * size
        self.minadd = [0] * size
        self.maxdel = [-1] * size
        self.count = 0
        self.total = 0

    def choose_minadd(self, i: int, j: int) -> int:
        if i == 0:
            return j
        if j == 0:
            return i
        if self.values[i] != self.values[j]:
            return i if self.values[i] < self.values[j] else j
        return max(i, j)

    def choose_maxdel(self, i: int, j: int) -> int:
        if i == -1:
            return j
        if j == -1:
            return i
        if i == 0 or j == 0:
            return 0
        if self.values[i] != self.values[j]:
            return i if self.values[i] > self.values[j] else j
        return min(i, j)

    def update_path(self, i: int) -> None:
        p = (self.base + i) >> 1
        while p:
            left = p << 1
            right = left | 1
            self.sum[p] = self.sum[left] + self.sum[right]
            self.pmin[p] = min(self.pmin[left], self.sum[left] + self.pmin[right])
            self.smax[p] = max(self.smax[left] + self.sum[right], self.smax[right])
            self.minadd[p] = self.choose_minadd(self.minadd[left], self.minadd[right])
            self.maxdel[p] = self.choose_maxdel(self.maxdel[left], self.maxdel[right])
            p >>= 1

    def next_bridge(self, i: int) -> int:
        stop = i + 1
        left = self.base
        right = self.base + stop
        acc = 0
        while left < right:
            if left & 1:
                acc += self.sum[left]
                left += 1
            if right & 1:
                right -= 1
                acc += self.sum[right]
            left >>= 1
            right >>= 1
        if acc == 0:
            return stop
        node = self.base + stop
        while True:
            while (node & 1) == 0:
                node >>= 1
            if acc + self.pmin[node] == 0:
                while node < self.base:
                    node <<= 1
                    if acc + self.pmin[node] > 0:
                        acc += self.sum[node]
                        node += 1
                return node - self.base
            acc += self.sum[node]
            node += 1
            if (node & -node) == node:
                return self.base

    def prev_bridge(self, i: int) -> int:
        left = self.base + i
        right = self.base * 2
        acc = 0
        while left < right:
            if left & 1:
                acc += self.sum[left]
                left += 1
            if right & 1:
                right -= 1
                acc += self.sum[right]
            left >>= 1
            right >>= 1
        if acc == 0:
            return i
        node = self.base + i
        while True:
            node -= 1
            while node > 1 and (node & 1):
                node >>= 1
            if self.smax[node] + acc == 0:
                while node < self.base:
                    node = (node << 1) | 1
                    if self.smax[node] + acc < 0:
                        acc += self.sum[node]
                        node -= 1
                return node - self.base
            acc += self.sum[node]
            if (node & -node) == node:
                return 0

    def query_minadd(self, i: int) -> int:
        left = self.base
        right = self.base + self.next_bridge(i)
        answer = 0
        while left < right:
            if left & 1:
                answer = self.choose_minadd(answer, self.minadd[left])
                left += 1
            if right & 1:
                right -= 1
                answer = self.choose_minadd(answer, self.minadd[right])
            left >>= 1
            right >>= 1
        return answer

    def query_maxdel(self, i: int) -> int:
        left = self.base + self.prev_bridge(i)
        right = self.base * 2
        answer = -1
        while left < right:
            if left & 1:
                answer = self.choose_maxdel(answer, self.maxdel[left])
                left += 1
            if right & 1:
                right -= 1
                answer = self.choose_maxdel(answer, self.maxdel[right])
            left >>= 1
            right >>= 1
        return answer

    def push(self, i: int) -> None:
        k = self.query_maxdel(i)
        leaf = self.base + i
        if self.choose_maxdel(i, k) == i:
            self.total += self.values[i]
            self.count += 1
            self.minadd[leaf] = i
            self.update_path(i)
            return
        self.maxdel[leaf] = i
        self.sum[leaf] = 1
        self.smax[leaf] = 1
        self.update_path(i)
        mate = self.base + k
        if k == 0:
            self.sum[mate] -= 1
            self.smax[mate] -= 1
            if self.sum[mate] == 0:
                self.maxdel[mate] = -1
        else:
            self.total += self.values[k]
            self.count += 1
            self.minadd[mate] = k
            self.maxdel[mate] = -1
            self.sum[mate] = 0
            self.smax[mate] = 0
        self.update_path(k)

    def unpush(self, i: int) -> None:
        leaf = self.base + i
        if self.sum[leaf] == 0:
            self.total -= self.values[i]
            self.count -= 1
            self.minadd[leaf] = 0
            self.update_path(i)
            return
        k = self.query_minadd(i)
        self.maxdel[leaf] = -1
        self.sum[leaf] = 0
        self.smax[leaf] = 0
        self.update_path(i)
        mate = self.base + k
        if k > 0:
            self.total -= self.values[k]
            self.count -= 1
        self.minadd[mate] = 0
        self.maxdel[mate] = k
        self.sum[mate] += 1
        self.smax[mate] += 1
        self.update_path(k)

    def pop(self, i: int) -> None:
        k = self.query_minadd(i)
        leaf = self.base + i
        self.sum[leaf] = -1
        self.pmin[leaf] = -1
        self.update_path(i)
        if k > 0:
            self.total -= self.values[k]
            self.count -= 1
        mate = self.base + k
        self.minadd[mate] = 0
        self.maxdel[mate] = k
        self.sum[mate] += 1
        self.smax[mate] += 1
        self.update_path(k)

    def unpop(self, i: int) -> None:
        k = self.query_maxdel(i)
        leaf = self.base + i
        mate = self.base + k
        self.sum[leaf] = 0
        self.pmin[leaf] = 0
        self.update_path(i)
        if k == 0:
            self.sum[mate] -= 1
            self.smax[mate] -= 1
            if self.sum[mate] == 0:
                self.maxdel[mate] = -1
        else:
            self.total += self.values[k]
            self.count += 1
            self.minadd[mate] = k
            self.maxdel[mate] = -1
            self.sum[mate] = 0
            self.smax[mate] = 0
        self.update_path(k)

    def set_operation(self, zero_based_i: int, kind: int, value: int) -> None:
        i = zero_based_i + 1
        if self.types[i] == 0:
            self.unpush(i)
        elif self.types[i] == 1:
            self.unpop(i)
        self.types[i] = kind
        self.values[i] = value
        if kind == 0:
            self.push(i)
        elif kind == 1:
            self.pop(i)


def _parse(values: list[int], input_is_null: bool, input_length: int | None):
    if input_is_null or not isinstance(values, list):
        return None
    length = len(values) if input_length is None else input_length
    if length != len(values) or length < 2 or length > MAX_PARSEABLE_INPUT_LENGTH:
        return None
    n, q = values[0], values[1]
    if not (1 <= n <= MAX_N and 1 <= q <= MAX_Q):
        return None
    if length != 2 + 2 * n + 3 * q:
        return None
    initial: list[tuple[int, int]] = []
    at = 2
    for _ in range(n):
        kind, value = values[at], values[at + 1]
        at += 2
        if kind == 0:
            if not 0 <= value <= 1_000_000:
                return None
        elif kind in (1, 2):
            if value != -1:
                return None
        else:
            return None
        initial.append((kind, value))
    updates: list[tuple[int, int, int]] = []
    for _ in range(q):
        index, kind, value = values[at], values[at + 1], values[at + 2]
        at += 3
        if not 0 <= index < n or kind not in (0, 1, 2):
            return None
        if kind == 0:
            if not 0 <= value <= 1_000_000:
                return None
        elif value != -1:
            return None
        updates.append((index, kind, value))
    return n, initial, updates


def expected_result(
    values: list[int],
    input_is_null: bool = False,
    input_length: int | None = None,
    output_is_null: bool = False,
    output_capacity: int | None = None,
) -> tuple[int, bytes]:
    parsed = _parse(values, input_is_null, input_length)
    if parsed is None:
        return INVALID_RESULT, b""
    n, initial, updates = parsed
    tree = _Tree(n)
    for i, (kind, value) in enumerate(initial):
        tree.set_operation(i, kind, value)
    result = bytearray()
    for index, kind, value in updates:
        tree.set_operation(index, kind, value)
        result.extend(struct.pack("<qq", tree.count, tree.total))
    if output_is_null or (output_capacity is not None and output_capacity < len(result)):
        return OUTPUT_ERROR, b""
    return len(result), bytes(result)
