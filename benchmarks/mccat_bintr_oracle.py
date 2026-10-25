"""Independent bounded oracle for McCat 17-bintr's tree summary and probes."""

from __future__ import annotations

import math
import struct
from collections.abc import Sequence

MAX_NODES = 64
QUERY_COUNT = 100
MAX_INPUT_LENGTH = MAX_NODES + 102
OUTPUT_BYTES = 33
INVALID_RESULT = -1
OUTPUT_ERROR = -2


def _build(values: Sequence[int]) -> tuple[list[int], list[int], list[int], int]:
    keys: list[int] = []
    left: list[int] = []
    right: list[int] = []
    root = -1
    for value in values:
        if root < 0:
            root = 0
            keys.append(value)
            left.append(-1)
            right.append(-1)
            continue
        node = root
        while True:
            if value == keys[node]:
                break
            branch = left if value < keys[node] else right
            child = branch[node]
            if child < 0:
                child = len(keys)
                branch[node] = child
                keys.append(value)
                left.append(-1)
                right.append(-1)
                break
            node = child
    return keys, left, right, root


def _measure(keys: Sequence[int], left: Sequence[int], right: Sequence[int], node: int) -> tuple[int, float]:
    if node < 0:
        return 0, 0.0
    left_count, left_sum = _measure(keys, left, right, left[node])
    right_count, right_sum = _measure(keys, left, right, right[node])
    return 1 + left_count + right_count, float(keys[node]) + left_sum + right_sum


def _contains_dfs(keys: Sequence[int], left: Sequence[int], right: Sequence[int], node: int, sought: int) -> bool:
    if node < 0:
        return False
    if keys[node] == sought:
        return True
    return (_contains_dfs(keys, left, right, left[node], sought)
            or _contains_dfs(keys, left, right, right[node], sought))


def expected_output(
    values: Sequence[int] | None,
    output_capacity: int | None = OUTPUT_BYTES,
    output_is_null: bool = False,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> tuple[int, bytes]:
    if input_is_null or not isinstance(values, (list, tuple)):
        return INVALID_RESULT, b""
    if any(type(value) is not int or not -(1 << 63) <= value < (1 << 63) for value in values):
        return INVALID_RESULT, b""
    actual_length = len(values) if input_length is None else input_length
    if (type(actual_length) is not int or actual_length < 103
            or actual_length > MAX_INPUT_LENGTH or len(values) != actual_length):
        return INVALID_RESULT, b""
    node_count = values[0]
    if (not 1 <= node_count <= MAX_NODES or actual_length != node_count + 102
            or values[node_count + 1] != QUERY_COUNT):
        return INVALID_RESULT, b""
    nodes = values[1:1 + node_count]
    probes = values[node_count + 2:node_count + 2 + QUERY_COUNT]
    if (len(probes) != QUERY_COUNT
            or any(value == 0 or not -32768 <= value <= 32767 for value in nodes)
            or any(value == 0 or not -32768 <= value <= 32767 for value in probes)):
        return INVALID_RESULT, b""
    if output_is_null or (output_capacity is not None and
                          (type(output_capacity) is not int or output_capacity < OUTPUT_BYTES)):
        return OUTPUT_ERROR, b""

    keys, left, right, root = _build(nodes)
    size, total = _measure(keys, left, right, root)
    mean = total / size
    if not math.isfinite(mean):
        return INVALID_RESULT, b""
    output = bytearray(struct.pack("<I", size) + struct.pack("<d", total) + struct.pack("<d", mean))
    bitmap = bytearray(13)
    for index, probe in enumerate(probes):
        if _contains_dfs(keys, left, right, root, probe):
            bitmap[index // 8] |= 1 << (index & 7)
    output.extend(bitmap)
    return OUTPUT_BYTES, bytes(output)
