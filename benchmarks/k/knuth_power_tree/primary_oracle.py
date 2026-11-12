"""Parent-map oracle for Knuth's shared power tree."""
from __future__ import annotations

import struct
from collections.abc import Sequence

MAX_TARGET = 127
MAX_OUTPUT_BYTES = 8 * (MAX_TARGET + 1)
INVALID_RESULT = -1
OUTPUT_ERROR_RESULT = -2


def _parse(values: Sequence[int] | None, input_is_null: bool,
           input_length: int | None) -> int | None:
    if (input_is_null or not isinstance(values, (list, tuple))
            or not 1 <= len(values) <= 2
            or (input_length is not None
                and (type(input_length) is not int or input_length != len(values)
                     or not 0 <= input_length <= 2))
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return None
    if len(values) != 1 or not 1 <= values[0] <= MAX_TARGET:
        return None
    return values[0]


def _tree_path(target: int) -> list[int]:
    if target == 1:
        return [1]
    parent = [0] * (MAX_TARGET + 1)
    seen = bytearray(MAX_TARGET + 1)
    queue = [1]
    seen[1] = 1
    head = 0
    while head < len(queue):
        current = queue[head]
        head += 1
        reverse_path: list[int] = []
        node = current
        while node != 0:
            reverse_path.append(node)
            node = parent[node]
        for ancestor in reversed(reverse_path):
            child = current + ancestor
            if child > target or seen[child]:
                continue
            parent[child] = current
            seen[child] = 1
            if child == target:
                result = [child]
                node = current
                while node != 0:
                    result.append(node)
                    node = parent[node]
                result.reverse()
                return result
            queue.append(child)
    raise ValueError("positive target was not reached by the power tree")


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    target = _parse(values, input_is_null, input_length)
    if target is None:
        return INVALID_RESULT, b""
    path = _tree_path(target)
    required = 8 * (len(path) + 1)
    effective_capacity = MAX_OUTPUT_BYTES if capacity is None else capacity
    if (type(output_is_null) is not bool or type(effective_capacity) is not int
            or effective_capacity < 0 or output_is_null
            or effective_capacity < required):
        return OUTPUT_ERROR_RESULT, b""
    payload = struct.pack("<" + "q" * (len(path) + 1), len(path) - 1, *path)
    return len(payload), payload
