"""Stockmeyer skyline-DP oracle for bounded slicing-floorplan orientation."""

from __future__ import annotations

import struct
from collections.abc import Sequence

MAX_LEAVES = 8
MAX_INPUT_LENGTH = 32
OUTPUT_SIZE = 32


def _parse(values: Sequence[int] | None):
    if (not isinstance(values, (list, tuple)) or not 4 <= len(values) <= MAX_INPUT_LENGTH
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return None
    leaves = values[0]
    if not 1 <= leaves <= MAX_LEAVES:
        return None
    nodes = []
    stack = []
    position = 1
    leaf_index = 0
    internal_count = 0
    while position < len(values):
        token = values[position]
        position += 1
        if token == 2:
            if position + 2 > len(values) or leaf_index >= leaves:
                return None
            height, width = values[position], values[position + 1]
            position += 2
            if not 1 <= height <= 20 or not 1 <= width <= 20:
                return None
            nodes.append({"op": 2, "left": -1, "right": -1,
                          "leaf": leaf_index, "height": height, "width": width})
            stack.append(len(nodes) - 1)
            leaf_index += 1
        elif token in (0, 1):
            if len(stack) < 2 or internal_count >= leaves - 1:
                return None
            right, left = stack.pop(), stack.pop()
            if nodes[right]["op"] == token:
                return None
            nodes.append({"op": token, "left": left, "right": right,
                          "leaf": -1, "height": 0, "width": 0})
            stack.append(len(nodes) - 1)
            internal_count += 1
        else:
            return None
    if (position != len(values) or leaf_index != leaves or internal_count != leaves - 1
            or len(nodes) != 2 * leaves - 1 or len(stack) != 1):
        return None
    return leaves, nodes, stack[0]


def _mask_key(mask: int, leaves: int) -> tuple[int, ...]:
    return tuple((mask >> bit) & 1 for bit in range(leaves))


def _skyline(candidates: list[tuple[int, int, int]], leaves: int) -> list[tuple[int, int, int]]:
    keep = [True] * len(candidates)
    for i, (height, width, mask) in enumerate(candidates):
        for j, (other_height, other_width, other_mask) in enumerate(candidates):
            if i == j:
                continue
            if other_height <= height and other_width <= width:
                if other_height < height or other_width < width:
                    keep[i] = False
                    break
                if _mask_key(other_mask, leaves) < _mask_key(mask, leaves):
                    keep[i] = False
                    break
                if other_mask == mask and j < i:
                    keep[i] = False
                    break
    return [candidate for candidate, retained in zip(candidates, keep) if retained]


def _solve(parsed) -> bytes:
    leaves, nodes, root = parsed
    lists: list[list[tuple[int, int, int]]] = [[] for _ in nodes]
    for index, node in enumerate(nodes):
        if node["op"] == 2:
            bit = 1 << node["leaf"]
            lists[index] = [(node["height"], node["width"], 0),
                            (node["width"], node["height"], bit)]
            lists[index] = _skyline(lists[index], leaves)
            continue
        left_list = lists[node["left"]]
        right_list = lists[node["right"]]
        joined = []
        for left_h, left_w, left_mask in left_list:
            for right_h, right_w, right_mask in right_list:
                if node["op"] == 0:  # vertical slice
                    joined.append((max(left_h, right_h), left_w + right_w,
                                   left_mask | right_mask))
                else:  # horizontal slice
                    joined.append((left_h + right_h, max(left_w, right_w),
                                   left_mask | right_mask))
        lists[index] = _skyline(joined, leaves)
    height, width, mask = min(
        lists[root], key=lambda candidate:
            (candidate[0] * candidate[1], candidate[0], candidate[1],
             _mask_key(candidate[2], leaves)))
    return struct.pack("<4q", height * width, height, width, mask)


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
    parsed = _parse(values)
    if parsed is None:
        return -1, b""
    payload = _solve(parsed)
    if output_is_null or capacity is not None and capacity < len(payload):
        return -2, b""
    return len(payload), payload
