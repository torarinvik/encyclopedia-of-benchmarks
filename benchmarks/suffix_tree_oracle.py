"""Oracle for the bounded Rust compressed suffix-tree construction workload."""

from __future__ import annotations

import math
import struct
from collections.abc import Sequence

MAX_TEXT_LENGTH = 64
MAX_VALID_INPUT_VALUES = 1 + MAX_TEXT_LENGTH
MAX_PARSEABLE_INPUT_VALUES = MAX_VALID_INPUT_VALUES + 1
MAX_OUTPUT_BYTES = MAX_TEXT_LENGTH * (MAX_TEXT_LENGTH + 1) // 2 + 48 * MAX_TEXT_LENGTH + 24
INVALID_RESULT = -1
OUTPUT_ERROR = -2
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1


def _decode_input(values: Sequence[int] | None):
    if (
        not isinstance(values, (list, tuple))
        or not 1 <= len(values) <= MAX_PARSEABLE_INPUT_VALUES
        or any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values)
    ):
        return None

    text_length = values[0]
    if not 0 <= text_length <= MAX_TEXT_LENGTH:
        return None
    if len(values) != 1 + text_length:
        return None
    codes = values[1:]
    if any(not 0 <= code <= 127 for code in codes):
        return None
    return bytes(codes)


def _build_nodes(text: bytes) -> list[dict[str, object]]:
    """Mirror the pinned Rust suffix insertion and edge-splitting loop on ASCII."""
    nodes: list[dict[str, object]] = [{"sub": b"", "children": []}]
    for start in range(len(text)):
        suffix = text[start:]
        node_index = 0
        offset = 0
        while offset < len(suffix):
            first = suffix[offset : offset + 1]
            children = nodes[node_index]["children"]
            child_slot = 0
            added_leaf = False
            while True:
                if child_slot == len(children):
                    new_index = len(nodes)
                    nodes.append({"sub": suffix[offset:], "children": []})
                    children.append(new_index)
                    added_leaf = True
                    break
                next_index = children[child_slot]
                label = nodes[next_index]["sub"]
                if label[:1] == first:
                    break
                child_slot += 1
            if added_leaf:
                # The pinned source returns from add_suffix after adding a new edge.
                break

            next_index = children[child_slot]
            label = nodes[next_index]["sub"]
            common = 0
            while common < len(label):
                if suffix[offset + common : offset + common + 1] != label[common : common + 1]:
                    old_index = next_index
                    next_index = len(nodes)
                    nodes.append({"sub": label[:common], "children": [old_index]})
                    nodes[old_index]["sub"] = label[common:]
                    children[child_slot] = next_index
                    break
                common += 1
            offset += common
            node_index = next_index

    return nodes


def _serialize(nodes: list[dict[str, object]]) -> bytes:
    output = bytearray(struct.pack("<Q", len(nodes)))
    for node in nodes:
        label = node["sub"]
        children = node["children"]
        output.extend(struct.pack("<Q", len(label)))
        output.extend(label)
        output.extend(struct.pack("<Q", len(children)))
        for child in children:
            output.extend(struct.pack("<Q", child))
    return bytes(output)


def expected_output(
    values: Sequence[int] | None,
    output_capacity: int | None = None,
    output_is_null: bool = False,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> tuple[int, bytes]:
    """Return serialized source nodes or the documented ABI error."""
    if type(output_is_null) is not bool or type(input_is_null) is not bool:
        return INVALID_RESULT, b""
    if output_capacity is not None and (type(output_capacity) is not int or output_capacity < 0):
        return INVALID_RESULT, b""
    if input_length is not None and (type(input_length) is not int or input_length < 0):
        return INVALID_RESULT, b""
    if input_is_null or values is None or not isinstance(values, (list, tuple)):
        return INVALID_RESULT, b""
    if input_length is not None and input_length != len(values):
        return INVALID_RESULT, b""

    text = _decode_input(values)
    if text is None:
        return INVALID_RESULT, b""
    output = _serialize(_build_nodes(text))
    if output_is_null or (output_capacity is not None and output_capacity < len(output)):
        return OUTPUT_ERROR, b""
    return len(output), output
