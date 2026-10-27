"""Compressed suffix-tree path traversal and descendant-leaf oracle."""
from __future__ import annotations

import struct
from collections.abc import Sequence

MAX_TEXT = 24
MAX_PATTERN = 12
MAX_VALID_INPUT_LENGTH = 2 + MAX_TEXT + MAX_PATTERN
MAX_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_OUTPUT_BYTES = 8 * (1 + MAX_TEXT)


def _tree(text: list[int]):
    # The internal -1 terminator is outside the accepted ASCII alphabet.
    seq = [*text, -1]
    nodes = [{"start": 0, "length": 0, "suffix": -1, "children": []}]
    for start in range(len(seq)):
        offset = 0
        node_id = 0
        while start + offset < len(seq):
            children = nodes[node_id]["children"]
            edge_pos = next((j for j, child in enumerate(children)
                             if seq[nodes[child]["start"]] == seq[start + offset]), None)
            suffix_length = len(seq) - start
            if edge_pos is None:
                leaf = len(nodes)
                nodes.append({"start": start + offset, "length": suffix_length - offset,
                              "suffix": start, "children": []})
                children.append(leaf)
                break
            child = children[edge_pos]
            common = 0
            while (common < nodes[child]["length"] and start + offset + common < len(seq)
                   and seq[nodes[child]["start"] + common] == seq[start + offset + common]):
                common += 1
            if common == nodes[child]["length"]:
                offset += common
                node_id = child
                continue
            split = len(nodes)
            old_start = nodes[child]["start"]
            old_length = nodes[child]["length"]
            nodes.append({"start": old_start, "length": common, "suffix": -1,
                          "children": [child]})
            nodes[child]["start"] = old_start + common
            nodes[child]["length"] = old_length - common
            children[edge_pos] = split
            offset += common
            node_id = split
    return seq, nodes


def _matches(text: list[int], pattern: list[int]) -> list[int]:
    seq, nodes = _tree(text)
    node_id = 0
    offset = 0
    while offset < len(pattern):
        children = nodes[node_id]["children"]
        child = next((child for child in children
                      if seq[nodes[child]["start"]] == pattern[offset]), None)
        if child is None:
            return []
        label_start = nodes[child]["start"]
        label_length = nodes[child]["length"]
        consumed = min(label_length, len(pattern) - offset)
        if seq[label_start:label_start + consumed] != pattern[offset:offset + consumed]:
            return []
        offset += consumed
        node_id = child
        if offset == len(pattern):
            break
        if consumed < label_length:
            return []
    starts: list[int] = []
    stack = [node_id]
    while stack:
        current = stack.pop()
        if nodes[current]["suffix"] >= 0:
            starts.append(nodes[current]["suffix"])
        # Child order is irrelevant here because a final suffix-order sort is
        # the deterministic leaf-order refinement used by the package.
        stack.extend(nodes[current]["children"])
    starts.sort(key=lambda pos: tuple(seq[pos:]))
    return starts


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
    if input_is_null or values is None or not isinstance(values, (list, tuple)):
        return -1, b""
    if len(values) < 3 or len(values) > MAX_INPUT_LENGTH or any(
            type(x) is not int or not -(1 << 63) <= x < (1 << 63) for x in values):
        return -1, b""
    n = values[0]
    if not 0 <= n <= MAX_TEXT or len(values) < 2 + n:
        return -1, b""
    m = values[1 + n]
    if not 1 <= m <= MAX_PATTERN or len(values) != 2 + n + m:
        return -1, b""
    text = list(values[1:1 + n])
    pattern = list(values[2 + n:])
    if any(not 0 <= ch <= 127 for ch in text + pattern):
        return -1, b""
    starts = _matches(text, pattern)
    payload = struct.pack("<" + "q" * (1 + len(starts)), len(starts), *starts)
    if output_is_null or capacity is not None and capacity < len(payload):
        return -2, b""
    return len(payload), payload
