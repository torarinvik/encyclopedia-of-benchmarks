"""Adjacent-sample LCA construction for the bounded K-quadtree point stage."""

from __future__ import annotations

import struct

MAX_N = 32
MAX_DEPTH = 8
MAX_VALID_INPUT_LENGTH = 3 + 2 * MAX_N
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_SPLITS = MAX_N - 1
MAX_OUTPUT_BYTES = 8 * (1 + 2 * MAX_SPLITS)
WORKSPACE_BYTES = 4096
INVALID_RESULT = -1
OUTPUT_ERROR = -2


def _morton_key(x: int, y: int, depth: int) -> int:
    key = 0
    for bit in range(depth - 1, -1, -1):
        # The source order is SW, NW, SE, NE, with y increasing upward.
        # Thus each base-4 digit is 2*x_bit + y_bit.
        key = (key << 2) | (((x >> bit) & 1) * 2 + ((y >> bit) & 1))
    return key


def _parse(values, input_length=None, input_is_null=False):
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple))
            or not 3 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)
            or input_length is not None
            and (type(input_length) is not int or input_length != len(values))):
        return None
    n, stride, depth = values[:3]
    if type(n) is not int or not 1 <= n <= MAX_N:
        return None
    if type(stride) is not int or not 1 <= stride <= n:
        return None
    if type(depth) is not int or not 1 <= depth <= MAX_DEPTH:
        return None
    if len(values) != 3 + 2 * n:
        return None
    side = 1 << depth
    points = []
    seen = set()
    for index in range(n):
        x, y = values[3 + 2 * index:5 + 2 * index]
        if not 0 <= x < side or not 0 <= y < side or (x, y) in seen:
            return None
        seen.add((x, y))
        points.append((_morton_key(x, y, depth), x, y))
    points.sort(key=lambda item: item[0])
    return n, stride, depth, points


def _simulate(values, input_length=None, input_is_null=False):
    parsed = _parse(values, input_length, input_is_null)
    if parsed is None:
        return None
    n, stride, depth, points = parsed
    samples = points[::stride]
    splits = set()
    for left, right in zip(samples, samples[1:]):
        left_key, right_key = left[0], right[0]
        common_depth = 0
        while common_depth < depth:
            shift = 2 * (depth - common_depth - 1)
            if ((left_key >> shift) & 3) != ((right_key >> shift) & 3):
                break
            common_depth += 1
        prefix = left_key >> (2 * (depth - common_depth)) if common_depth else 0
        splits.add((common_depth, prefix))
    ordered = sorted(splits, key=lambda item: (item[1] << (2 * (depth - item[0])), item[0]))
    words = [len(ordered)]
    for split_depth, prefix in ordered:
        words.extend((split_depth, prefix))
    return words


def expected_output(values, output_capacity=None, output_is_null=False,
                    input_is_null=False, input_length=None):
    words = _simulate(values, input_length, input_is_null)
    if words is None:
        return INVALID_RESULT, b""
    payload = b"".join(struct.pack("<q", word) for word in words)
    if (type(output_is_null) is not bool or output_is_null
            or output_capacity is not None
            and (type(output_capacity) is not int or output_capacity < len(payload))):
        return OUTPUT_ERROR, b""
    return len(payload), payload
