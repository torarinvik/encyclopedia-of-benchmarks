"""Oracle for the bounded indexed-BST floor and ceiling benchmark."""

from __future__ import annotations

import struct

MAX_NODE_COUNT = 127
VALUE_MIN, VALUE_MAX = -1_000_000, 1_000_000
MAX_INPUT_LENGTH = 3 + 3 * MAX_NODE_COUNT
OUTPUT_BYTES = 16
INVALID_STATUS = -1
CAPACITY_STATUS = -2
NO_VALUE = -(2**63)


def expected_output(values: tuple[int, ...] | list[int], output_capacity: int | None = None) -> tuple[int, bytes]:
    if (not isinstance(values, (tuple, list)) or not 3 <= len(values) <= MAX_INPUT_LENGTH
            or any(type(value) is not int or not -(2**63) <= value < 2**63 for value in values)):
        return INVALID_STATUS, b""
    count, root, key = values[:3]
    if not 0 <= count <= MAX_NODE_COUNT or not VALUE_MIN <= key <= VALUE_MAX:
        return INVALID_STATUS, b""
    if len(values) != 3 + 3 * count:
        return INVALID_STATUS, b""
    if count == 0:
        if root != -1:
            return INVALID_STATUS, b""
    elif not 0 <= root < count:
        return INVALID_STATUS, b""
    nodes = []
    for i in range(count):
        value, left, right = values[3 + 3*i:6 + 3*i]
        if not VALUE_MIN <= value <= VALUE_MAX or any(child < -1 or child >= count for child in (left, right)):
            return INVALID_STATUS, b""
        nodes.append((value, left, right))
    # Require a proper strict BST whose nodes are all reachable exactly once.
    if count:
        parents = [0] * count
        for _, left, right in nodes:
            for child in (left, right):
                if child >= 0:
                    parents[child] += 1
        if parents[root] != 0 or any(parents[i] != 1 for i in range(count) if i != root):
            return INVALID_STATUS, b""
        stack = [(root, None, None)]
        seen = set()
        while stack:
            index, low, high = stack.pop()
            if index in seen:
                return INVALID_STATUS, b""
            seen.add(index)
            value, left, right = nodes[index]
            if (low is not None and value <= low) or (high is not None and value >= high):
                return INVALID_STATUS, b""
            if left >= 0:
                stack.append((left, low, value))
            if right >= 0:
                stack.append((right, value, high))
        if len(seen) != count:
            return INVALID_STATUS, b""
    if output_capacity is not None:
        if type(output_capacity) is not int or output_capacity < 0:
            return INVALID_STATUS, b""
        if output_capacity < OUTPUT_BYTES:
            return CAPACITY_STATUS, b""
    floor = ceiling = NO_VALUE
    current = root
    while current >= 0:
        value, left, right = nodes[current]
        if value == key:
            floor = ceiling = value
            break
        if key < value:
            ceiling = value
            current = left
        else:
            floor = value
            current = right
    output = struct.pack("<qq", floor, ceiling)
    return OUTPUT_BYTES, output
