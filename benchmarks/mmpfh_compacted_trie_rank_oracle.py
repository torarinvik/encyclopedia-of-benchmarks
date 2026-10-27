"""Primary bounded compacted-trie ranking model for Encyclopedia DOI 639."""
from __future__ import annotations

import struct
from collections.abc import Sequence

MAX_WIDTH = 16
MAX_KEYS = 16
MAX_QUERIES = 16
MAX_INPUT_LENGTH = 3 + MAX_KEYS + MAX_QUERIES
MAX_OUTPUT_VALUES = 3 + 5 * (2 * MAX_KEYS - 1) + MAX_QUERIES
MAX_OUTPUT_BYTES = MAX_OUTPUT_VALUES * 8


def _decode(values: Sequence[int] | None):
    if (not isinstance(values, (list, tuple)) or not 3 <= len(values) <= MAX_INPUT_LENGTH
            or any(type(x) is not int or not -(1 << 63) <= x < (1 << 63) for x in values)):
        return None
    width, count, qcount = values[:3]
    if not 1 <= width <= MAX_WIDTH or not 1 <= count <= MAX_KEYS or not 1 <= qcount <= MAX_QUERIES:
        return None
    if len(values) != 3 + count + qcount:
        return None
    limit = 1 << width
    keys = list(values[3:3 + count])
    queries = list(values[3 + count:])
    if any(not 0 <= x < limit for x in keys + queries) or any(a >= b for a, b in zip(keys, keys[1:])):
        return None
    return width, keys, queries


def _make_nodes(width: int, keys: list[int]):
    nodes: list[list[int]] = []

    def build(lo: int, hi: int) -> int:
        node_id = len(nodes)
        nodes.append([0, -1, -1, 0, 0])
        if hi - lo == 1:
            nodes[node_id] = [-1, -1, -1, keys[lo], keys[lo]]
            return node_id
        differing = keys[lo] ^ keys[hi - 1]
        bit = width - differing.bit_length()
        mask = 1 << (width - 1 - bit)
        split = lo
        while split < hi and keys[split] & mask == 0:
            split += 1
        left = build(lo, split)
        right = build(split, hi)
        nodes[node_id] = [bit, left, right, keys[lo], keys[hi - 1]]
        return node_id

    build(0, len(keys))
    return nodes


def _rank(width: int, nodes: list[list[int]], key_count: int, query: int) -> int:
    node_id = 0
    rank = 0
    while True:
        bit, left, right, low, high = nodes[node_id]
        if query < low:
            return rank
        if query > high:
            return rank + _leaf_count(nodes, node_id)
        if bit < 0:
            return rank
        if (query >> (width - 1 - bit)) & 1:
            rank += _leaf_count(nodes, left)
            node_id = right
        else:
            node_id = left


def _leaf_count(nodes: list[list[int]], root: int) -> int:
    stack = [root]
    count = 0
    while stack:
        node = nodes[stack.pop()]
        if node[0] < 0:
            count += 1
        else:
            stack.extend((node[1], node[2]))
    return count


def _compute(width: int, keys: list[int], queries: list[int]) -> list[int]:
    nodes = _make_nodes(width, keys)
    out = [len(keys), len(nodes), len(queries)]
    for node in nodes:
        out.extend(node)
    out.extend(_rank(width, nodes, len(keys), query) for query in queries)
    return out


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
    if decoded is None:
        return -1, b""
    words = _compute(*decoded)
    payload = struct.pack("<" + "q" * len(words), *words)
    if output_is_null or capacity is not None and capacity < len(payload):
        return -2, b""
    return len(payload), payload
