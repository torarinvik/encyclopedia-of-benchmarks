"""Recursive sampled-trie construction, independent of adjacent-pair LCAs."""

from __future__ import annotations

import struct

BAD = -1
NO_OUTPUT = -2
MAX_WORDS = 68
MAX_BYTES = 504


def _key(x, y, depth):
    path = []
    for bit in range(depth - 1, -1, -1):
        path.append((((x >> bit) & 1) << 1) | ((y >> bit) & 1))
    value = 0
    for digit in path:
        value = 4 * value + digit
    return value


def _simulate(frame, frame_length, null_input):
    if (type(null_input) is not bool or null_input
            or not isinstance(frame, (list, tuple))
            or not 3 <= len(frame) <= MAX_WORDS
            or any(type(v) is not int or not -(1 << 63) <= v < (1 << 63) for v in frame)
            or frame_length is not None
            and (type(frame_length) is not int or frame_length != len(frame))):
        return None
    n, stride, depth = frame[:3]
    if type(n) is not int or not 1 <= n <= 32:
        return None
    if type(stride) is not int or not 1 <= stride <= n:
        return None
    if type(depth) is not int or not 1 <= depth <= 8 or len(frame) != 3 + 2*n:
        return None
    side = 1 << depth
    seen = set()
    ordered = []
    for i in range(n):
        x, y = frame[3+2*i], frame[4+2*i]
        if not 0 <= x < side or not 0 <= y < side or (x, y) in seen:
            return None
        seen.add((x, y))
        ordered.append((_key(x, y, depth), x, y))
    ordered.sort(key=lambda p: p[0])
    sample_keys = [ordered[i][0] for i in range(0, n, stride)]
    splits = []

    def visit(keys, level, prefix):
        if len(keys) < 2:
            return
        if level >= depth:
            return
        groups = [[] for _ in range(4)]
        shift = 2 * (depth - level - 1)
        for key in keys:
            groups[(key >> shift) & 3].append(key)
        splits.append((level, prefix))
        for quadrant, child in enumerate(groups):
            if child:
                visit(child, level + 1, 4 * prefix + quadrant)

    visit(sample_keys, 0, 0)
    # Recursive quadrant order is already Z preorder. Serialize that order.
    words = [len(splits)]
    for level, prefix in splits:
        words.extend((level, prefix))
    return words


def expected_output(values, output_capacity=None, output_is_null=False,
                    input_is_null=False, input_length=None):
    words = _simulate(values, input_length, input_is_null)
    if words is None:
        return BAD, b""
    payload = b"".join(struct.pack("<q", word) for word in words)
    if (type(output_is_null) is not bool or output_is_null
            or output_capacity is not None
            and (type(output_capacity) is not int or output_capacity < len(payload))):
        return NO_OUTPUT, b""
    return len(payload), payload
