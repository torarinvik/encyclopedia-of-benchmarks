"""Explicit level-frontier verifier for deterministic power-tree paths."""
from __future__ import annotations

import struct
from collections.abc import Sequence

MAX_TARGET = 127
MAX_OUTPUT_BYTES = 8 * (MAX_TARGET + 1)


def _parse(values: Sequence[int] | None, input_is_null: bool,
           input_length: int | None) -> int | None:
    if (input_is_null or not isinstance(values, (list, tuple)) or len(values) != 1
            or (input_length is not None
                and (type(input_length) is not int or input_length != len(values)))
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return None
    target = values[0]
    return target if 1 <= target <= MAX_TARGET else None


def _level_path(target: int) -> tuple[int, ...]:
    if target == 1:
        return (1,)
    frontier: list[tuple[int, ...]] = [(1,)]
    known = {1}
    while frontier:
        following: list[tuple[int, ...]] = []
        for path in frontier:
            current = path[-1]
            for earlier in path:
                candidate = current + earlier
                if candidate > target or candidate in known:
                    continue
                known.add(candidate)
                child_path = path + (candidate,)
                if candidate == target:
                    return child_path
                following.append(child_path)
        frontier = following
    raise ValueError("positive target was not reached by the power tree")


def verify_result(values: Sequence[int] | None, result: int, output: bytes,
                  output_capacity: int | None = None, output_is_null: bool = False,
                  input_is_null: bool = False, input_length: int | None = None) -> bool:
    target = _parse(values, input_is_null, input_length)
    if target is None:
        return result == -1 and output == b""
    capacity = MAX_OUTPUT_BYTES if output_capacity is None else output_capacity
    if (type(output_is_null) is not bool or type(capacity) is not int or capacity < 0):
        return result == -2 and output == b""
    if output_is_null:
        return result == -2 and output == b""
    try:
        path = _level_path(target)
    except ValueError:
        return False
    required = 8 * (len(path) + 1)
    if capacity < required:
        return result == -2 and output == b""
    if not isinstance(output, (bytes, bytearray)) or result != required or len(output) != required:
        return False
    try:
        words = struct.unpack("<" + "q" * (len(path) + 1), output)
    except struct.error:
        return False
    steps, *reported_path = words
    if tuple(reported_path) != path or steps != len(path) - 1 or path[-1] != target:
        return False
    if path[0] != 1:
        return False
    for index in range(1, len(path)):
        addend = path[index] - path[index - 1]
        if path[index] <= path[index - 1] or addend not in path[:index]:
            return False
    return True
