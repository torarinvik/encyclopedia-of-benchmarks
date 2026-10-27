"""Integer scaled-likelihood oracle for the bounded binary-tree profile."""

from __future__ import annotations

import struct
from collections.abc import Sequence

MAX_LEAVES = 8
MAX_INPUT_LENGTH = 38
MAX_OUTPUT_BYTES = 8


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if (type(output_is_null) is not bool or type(input_is_null) is not bool or
            capacity is not None and (type(capacity) is not int or capacity < 0) or
            input_length is not None and (type(input_length) is not int or
                not 0 <= input_length <= MAX_INPUT_LENGTH)):
        return -1, b""
    if input_is_null or values is None or not isinstance(values, (list, tuple)):
        return -1, b""
    if input_length is not None and input_length != len(values):
        return -1, b""
    if not 3 <= len(values) <= MAX_INPUT_LENGTH or any(
            type(x) is not int or not -(1 << 63) <= x < (1 << 63) for x in values):
        return -1, b""
    n = values[0]
    if not 1 <= n <= MAX_LEAVES:
        return -1, b""
    at = 1
    leaves = internals = 0
    stack: list[tuple[int, int]] = []
    edge_count = 0
    while at < len(values):
        tag = values[at]
        at += 1
        if tag == 0:
            if at >= len(values) or values[at] not in (0, 1):
                return -1, b""
            state = values[at]
            at += 1
            stack.append((1, 0) if state == 0 else (0, 1))
            leaves += 1
        elif tag == 1:
            if at + 2 > len(values) or values[at] not in (0, 1) or values[at + 1] not in (0, 1) or len(stack) < 2:
                return -1, b""
            lm, rm = values[at], values[at + 1]
            at += 2
            right = stack.pop()
            left = stack.pop()
            pnum = ((4, 0), (0, 4)) if lm == 0 else ((3, 1), (1, 3))
            qnum = ((4, 0), (0, 4)) if rm == 0 else ((3, 1), (1, 3))
            stack.append(tuple(
                (pnum[s][0] * left[0] + pnum[s][1] * left[1]) *
                (qnum[s][0] * right[0] + qnum[s][1] * right[1])
                for s in (0, 1)
            ))
            internals += 1
            edge_count += 2
        else:
            return -1, b""
    if leaves != n or internals != n - 1 or len(stack) != 1 or edge_count != 2 * n - 2:
        return -1, b""
    shift = 29 - 2 * edge_count
    if shift < 0:
        return -1, b""
    scaled = (stack[0][0] + stack[0][1]) << shift
    if output_is_null or capacity is not None and capacity < 8:
        return -2, b""
    return 8, struct.pack("<q", scaled)
