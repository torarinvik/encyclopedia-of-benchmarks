"""Independent ancestry-walk verifier for the interleave lower bound."""

from __future__ import annotations

import struct
from collections.abc import Sequence

MAX_INPUT_LENGTH = 36


def _decode(data):
    if not isinstance(data, (tuple, list)) or not 3 <= len(data) <= MAX_INPUT_LENGTH:
        return None
    if any(type(value) is not int or not -(1 << 63) <= value < (1 << 63) for value in data):
        return None
    count, root = data[0], data[1]
    if not 1 <= count <= 8 or not 0 <= root < count:
        return None
    cursor = 2
    left, right = [], []
    for _ in range(count):
        if cursor + 2 > len(data):
            return None
        node = len(left)
        left_child, right_child = data[cursor], data[cursor + 1]
        cursor += 2
        if (left_child < -1 or left_child >= count or right_child < -1 or right_child >= count
                or left_child == node or right_child == node
                or left_child >= 0 and left_child == right_child):
            return None
        left.append(left_child)
        right.append(right_child)
    if cursor >= len(data):
        return None
    access_count = data[cursor]
    cursor += 1
    if not 0 <= access_count <= 16 or cursor + access_count != len(data):
        return None
    accesses = list(data[cursor:])
    if any(key < 0 or key >= count for key in accesses):
        return None
    parent = [-1] * count
    for node in range(count):
        for child in (left[node], right[node]):
            if child >= 0:
                if parent[child] != -1:
                    return None
                parent[child] = node
    if parent[root] != -1 or any(parent[node] == -1 for node in range(count) if node != root):
        return None

    visited = set()

    def check_subtree(node, lower, upper):
        if node < 0:
            return True
        if node in visited or not lower <= node <= upper:
            return False
        visited.add(node)
        return check_subtree(left[node], lower, node - 1) and check_subtree(right[node], node + 1, upper)

    if not check_subtree(root, 0, count - 1) or len(visited) != count:
        return None
    return count, parent, accesses


def _payload(decoded):
    count, parent, accesses = decoded
    total = 0
    for pivot in range(count):
        previous = None
        for key in accesses:
            ancestor = key
            while ancestor != -1 and ancestor != pivot:
                ancestor = parent[ancestor]
            if ancestor == pivot:
                side = 0 if key <= pivot else 1
                if previous is not None and side != previous:
                    total += 1
                previous = side
    return struct.pack("<q", total)


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
    decoded = _decode(values)
    if decoded is None:
        return -1, b""
    payload = _payload(decoded)
    if output_is_null or capacity is not None and capacity < len(payload):
        return -2, b""
    return len(payload), payload
