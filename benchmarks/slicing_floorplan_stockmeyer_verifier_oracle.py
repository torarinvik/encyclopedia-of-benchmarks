"""Independent orientation-enumeration verifier for the Stockmeyer profile."""

from __future__ import annotations

import struct
from collections.abc import Sequence

MAX_LEAVES = 8
MAX_INPUT_LENGTH = 32


def _parse(values: Sequence[int] | None):
    if (not isinstance(values, (list, tuple)) or not 4 <= len(values) <= MAX_INPUT_LENGTH
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return None
    leaves = values[0]
    if not 1 <= leaves <= MAX_LEAVES:
        return None
    nodes = []
    pending = []
    position = 1
    seen_leaves = 0
    seen_internal = 0
    while position < len(values):
        kind = values[position]
        position += 1
        if kind == 2:
            if position + 2 > len(values) or seen_leaves >= leaves:
                return None
            height, width = values[position:position + 2]
            position += 2
            if not 1 <= height <= 20 or not 1 <= width <= 20:
                return None
            nodes.append((2, -1, -1, seen_leaves, height, width))
            pending.append(len(nodes) - 1)
            seen_leaves += 1
        elif kind in (0, 1):
            if len(pending) < 2 or seen_internal >= leaves - 1:
                return None
            right = pending.pop()
            left = pending.pop()
            if nodes[right][0] == kind:
                return None
            nodes.append((kind, left, right, -1, 0, 0))
            pending.append(len(nodes) - 1)
            seen_internal += 1
        else:
            return None
    if (position != len(values) or seen_leaves != leaves or seen_internal != leaves - 1
            or len(nodes) != 2 * leaves - 1 or len(pending) != 1):
        return None
    return leaves, nodes, pending[0]


def _dims(node_index: int, nodes, orientation: int) -> tuple[int, int]:
    kind, left, right, leaf, height, width = nodes[node_index]
    if kind == 2:
        return (height, width) if not (orientation >> leaf) & 1 else (width, height)
    left_h, left_w = _dims(left, nodes, orientation)
    right_h, right_w = _dims(right, nodes, orientation)
    if kind == 0:
        return max(left_h, right_h), left_w + right_w
    return left_h + right_h, max(left_w, right_w)


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
    leaves, nodes, root = parsed
    winner = None
    for mask in range(1 << leaves):
        height, width = _dims(root, nodes, mask)
        key = (height * width, height, width,
               tuple((mask >> bit) & 1 for bit in range(leaves)))
        if winner is None or key < winner[0]:
            winner = key, mask, height, width
    assert winner is not None
    _, mask, height, width = winner
    payload = struct.pack("<4q", height * width, height, width, mask)
    if output_is_null or capacity is not None and capacity < len(payload):
        return -2, b""
    return len(payload), payload
