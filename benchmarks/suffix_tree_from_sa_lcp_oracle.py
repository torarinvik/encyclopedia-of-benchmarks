"""SA/LCP stack-construction oracle for a bounded suffix tree."""

from __future__ import annotations

import struct
from collections.abc import Sequence

MAX_TEXT_LENGTH = 8
MAX_INPUT_LENGTH = 10
MAX_NODES = 17
MAX_OUTPUT_BYTES = 8 * (1 + 5 * MAX_NODES)


def _parse(values: Sequence[int] | None) -> list[int] | None:
    if (not isinstance(values, (list, tuple)) or not 1 <= len(values) <= MAX_INPUT_LENGTH
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return None
    n = values[0]
    if not 0 <= n <= MAX_TEXT_LENGTH or len(values) != n + 1:
        return None
    text = list(values[1:])
    if any(byte < 1 or byte > 255 for byte in text):
        return None
    return text


def _suffix_data(text: Sequence[int]):
    symbols = [*text, 0]
    n = len(symbols)
    suffix_array = sorted(range(n), key=lambda start: tuple(symbols[start:]))
    lcp = [0] * n
    for rank in range(1, n):
        left = suffix_array[rank - 1]
        right = suffix_array[rank]
        common = 0
        while left + common < n and right + common < n \
                and symbols[left + common] == symbols[right + common]:
            common += 1
        lcp[rank] = common
    return symbols, suffix_array, lcp


def _canonical_payload(nodes: list[dict[str, int]]) -> bytes:
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


def _stack_tree(symbols: Sequence[int], suffix_array: Sequence[int], lcp: Sequence[int]):
    node_list = [{"parent": -1, "depth": 0, "rep": -1, "leaf": -1}]
    last_child = [-1]
    stack = [0]
    suffix_count = len(suffix_array)
    for rank, suffix_start in enumerate(suffix_array):
        if rank > 0:
            common = lcp[rank]
            while len(stack) > 1 and node_list[stack[-1]]["depth"] > common:
                stack.pop()
            top = stack[-1]
            if node_list[top]["depth"] < common:
                old_child = last_child[top]
                internal = len(node_list)
                node_list.append({"parent": top, "depth": common,
                                  "rep": node_list[old_child]["rep"], "leaf": -1})
                last_child.append(old_child)
                node_list[old_child]["parent"] = internal
                last_child[top] = internal
                stack.append(internal)
        parent = stack[-1]
        leaf = len(node_list)
        node_list.append({"parent": parent, "depth": suffix_count - suffix_start,
                          "rep": suffix_start, "leaf": suffix_start})
        last_child.append(-1)
        last_child[parent] = leaf
    return node_list


def _payload(values: Sequence[int] | None) -> bytes | None:
    text = _parse(values)
    if text is None:
        return None
    symbols, suffix_array, lcp = _suffix_data(text)
    return _canonical_payload(_stack_tree(symbols, suffix_array, lcp))


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
