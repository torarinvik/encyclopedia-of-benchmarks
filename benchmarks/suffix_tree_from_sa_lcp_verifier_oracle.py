"""Recursive compressed-trie verifier for suffix-tree workload outputs."""

from __future__ import annotations

import struct
from collections.abc import Sequence

MAX_TEXT_LENGTH = 8
MAX_INPUT_LENGTH = 10
MAX_OUTPUT_BYTES = 688


def _text(values: Sequence[int] | None):
    if (not isinstance(values, (tuple, list)) or not 1 <= len(values) <= MAX_INPUT_LENGTH
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return None
    n = values[0]
    if n < 0 or n > MAX_TEXT_LENGTH or len(values) != n + 1:
        return None
    symbols = list(values[1:])
    if any(symbol < 1 or symbol > 255 for symbol in symbols):
        return None
    return [*symbols, 0]


def _build_by_prefix_groups(symbols: Sequence[int]):
    suffix_array = sorted(range(len(symbols)), key=lambda start: tuple(symbols[start:]))
    suffix_count = len(suffix_array)
    nodes = [{"parent": -1, "depth": 0, "rep": -1, "leaf": -1}]

    def add(parent: int, depth: int, representative: int, leaf: int = -1) -> int:
        nodes.append({"parent": parent, "depth": depth,
                      "rep": representative, "leaf": leaf})
        return len(nodes) - 1

    def expand(parent: int, rank_start: int, rank_end: int, prefix_depth: int) -> None:
        groups: list[tuple[int, int]] = []
        begin = rank_start
        while begin < rank_end:
            suffix = suffix_array[begin]
            symbol = symbols[suffix + prefix_depth] if suffix + prefix_depth < suffix_count else -1
            end = begin + 1
            while end < rank_end:
                other_suffix = suffix_array[end]
                other_symbol = symbols[other_suffix + prefix_depth] \
                    if other_suffix + prefix_depth < suffix_count else -1
                if other_symbol != symbol:
                    break
                end += 1
            groups.append((begin, end))
            begin = end

        for begin, end in groups:
            representative = suffix_array[begin]
            if end - begin == 1:
                add(parent, suffix_count - representative, representative, representative)
                continue
            common = suffix_count
            for rank in range(begin + 1, end):
                left = suffix_array[rank - 1]
                right = suffix_array[rank]
                count = 0
                while left + count < suffix_count and right + count < suffix_count \
                        and symbols[left + count] == symbols[right + count]:
                    count += 1
                common = min(common, count)
            internal = add(parent, common, representative)
            expand(internal, begin, end, common)

    expand(0, 0, suffix_count, 0)
    return nodes


def _payload(values: Sequence[int] | None) -> bytes | None:
    symbols = _text(values)
    if symbols is None:
        return None
    nodes = _build_by_prefix_groups(symbols)
    records = []
    for index, node in enumerate(nodes):
        if index == 0:
            records.append((-1, -1, -1, 0, -1))
        else:
            parent = nodes[node["parent"]]
            records.append((parent["rep"], parent["depth"], node["rep"],
                            node["depth"], node["leaf"]))
    records.sort(key=lambda row: (row[3], row[2], row[4]))
    words = [len(nodes)]
    for record in records:
        words.extend(record)
    return struct.pack("<" + "q" * len(words), *words)


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or capacity is not None and (type(capacity) is not int or capacity < 0)
            or input_length is not None and (type(input_length) is not int
                                             or not 0 <= input_length <= MAX_INPUT_LENGTH)
            or input_is_null and values not in (None, [], ())
            or not input_is_null and values is not None and input_length is not None
            and input_length != len(values)):
        return -1, b""
    if input_is_null or values is None:
        return -1, b""
    payload = _payload(values)
    if payload is None:
        return -1, b""
    if output_is_null or capacity is not None and capacity < len(payload):
        return -2, b""
    return len(payload), payload
