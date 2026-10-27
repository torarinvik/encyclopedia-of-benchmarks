"""Independent full-bit-trie compression verifier for DOI 639 ranking."""
from __future__ import annotations

import struct
from collections.abc import Sequence

MAX_WIDTH = 16
MAX_KEYS = 16
MAX_QUERIES = 16
MAX_INPUT_LENGTH = 3 + MAX_KEYS + MAX_QUERIES
MAX_OUTPUT_BYTES = (3 + 5 * (2 * MAX_KEYS - 1) + MAX_QUERIES) * 8


def _decode(values: Sequence[int] | None):
    if (not isinstance(values, (list, tuple)) or not 3 <= len(values) <= MAX_INPUT_LENGTH
            or any(type(x) is not int or not -(1 << 63) <= x < (1 << 63) for x in values)):
        return None
    width, d, q = values[:3]
    if not 1 <= width <= MAX_WIDTH or not 1 <= d <= MAX_KEYS or not 1 <= q <= MAX_QUERIES or len(values) != 3 + d + q:
        return None
    keys = list(values[3:3 + d]); queries = list(values[3 + d:])
    if any(not 0 <= x < 1 << width for x in keys + queries) or keys != sorted(set(keys)):
        return None
    return width, keys, queries


def _compressed_trie(width: int, keys: list[int]):
    # Construct all bitwise prefixes first. The recursive compressor skips
    # unary chains, which is independent of the primary sorted-range split.
    full: dict = {}
    for key in keys:
        cur = full
        for bit in range(width):
            side = (key >> (width - 1 - bit)) & 1
            cur = cur.setdefault(side, {})
        cur["key"] = key
    records: list[list[int]] = []

    def compress(node: dict, depth: int) -> tuple[int, int, int, int]:
        if "key" in node:
            idx = len(records)
            records.append([-1, -1, -1, node["key"], node["key"]])
            return idx, 1, node["key"], node["key"]
        while len(node) == 1 and (0 in node or 1 in node):
            side = 0 if 0 in node else 1
            node = node[side]
            depth += 1
        if "key" in node:
            idx = len(records)
            records.append([-1, -1, -1, node["key"], node["key"]])
            return idx, 1, node["key"], node["key"]
        # At a branching node, bit depth identifies the tested prefix bit.
        idx = len(records)
        records.append([depth, -1, -1, 0, 0])
        left, lc, left_min, left_max = compress(node[0], depth + 1)
        right, rc, right_min, right_max = compress(node[1], depth + 1)
        records[idx] = [depth, left, right, left_min, right_max]
        return idx, lc + rc, left_min, right_max

    # Root may itself begin with a unary prefix; locate first divergence.
    _, leaves, _, _ = compress(full, 0)
    if leaves != len(keys):
        raise ValueError("trie leaf mismatch")
    return records


def _rank(width: int, records: list[list[int]], d: int, query: int) -> int:
    idx = 0
    rank = 0
    while True:
        bit, left, right, low, high = records[idx]
        if query < low:
            return rank
        if query > high:
            return rank + _subtree_leaves(records, idx)
        if bit < 0:
            return rank
        if query >> (width - 1 - bit) & 1:
            rank += _subtree_leaves(records, left)
            idx = right
        else:
            idx = left


def _subtree_leaves(records: list[list[int]], root: int) -> int:
    todo = [root]; total = 0
    while todo:
        bit, left, right, _, _ = records[todo.pop()]
        if bit < 0: total += 1
        else: todo.extend((left, right))
    return total


def _compute(width: int, keys: list[int], queries: list[int]) -> list[int]:
    nodes = _compressed_trie(width, keys)
    words = [len(keys), len(nodes), len(queries)]
    for record in nodes: words.extend(record)
    words.extend(_rank(width, nodes, len(keys), query) for query in queries)
    return words


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or capacity is not None and (type(capacity) is not int or capacity < 0)
            or input_length is not None and (type(input_length) is not int or input_length < 0)
            or input_is_null and values not in (None, [], ())
            or not input_is_null and values is not None and input_length is not None
            and input_length != len(values)):
        return -1, b""
    decoded = None if input_is_null else _decode(values)
    if decoded is None: return -1, b""
    words = _compute(*decoded)
    payload = struct.pack("<" + "q" * len(words), *words)
    if output_is_null or capacity is not None and capacity < len(payload): return -2, b""
    return len(payload), payload
