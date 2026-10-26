"""Direct-traversal verifier for bounded weighted list ranking."""

from __future__ import annotations

import struct
from collections.abc import Sequence

MAX_N = 16
MAX_INPUT = 2 + 2 * MAX_N
MAX_INPUT_LENGTH = MAX_INPUT
MAX_OUTPUT_BYTES = 8 * MAX_N


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or capacity is not None and (type(capacity) is not int or capacity < 0)
            or input_length is not None and
            (type(input_length) is not int or not 0 <= input_length <= MAX_INPUT)
            or input_is_null and values not in (None, [], ())
            or not input_is_null and values is not None and input_length is not None
            and isinstance(values, (list, tuple))
            and input_length != len(values)):
        return -1, b""
    if input_is_null or values is None or not isinstance(values, (list, tuple)):
        return -1, b""
    if (len(values) < 4 or len(values) > MAX_INPUT or any(
            type(value) is not int or not -(1 << 63) <= value < (1 << 63)
            for value in values)):
        return -1, b""
    n, head = values[0], values[1]
    if not 1 <= n <= MAX_N or len(values) != 2 + 2 * n or not 0 <= head < n:
        return -1, b""
    weights = values[2:2 + n]
    successors = values[2 + n:]
    if any(not 1 <= weight <= 10000 for weight in weights):
        return -1, b""
    if any(successor < -1 or successor >= n for successor in successors):
        return -1, b""

    predecessor = [-1] * n
    tail_count = 0
    for node, successor in enumerate(successors):
        if successor == -1:
            tail_count += 1
        else:
            if predecessor[successor] != -1:
                return -1, b""
            predecessor[successor] = node
    if tail_count != 1 or predecessor[head] != -1:
        return -1, b""

    ranks = [0] * n
    visited = [False] * n
    node = head
    prefix = 0
    count = 0
    while node != -1:
        if visited[node]:
            return -1, b""
        visited[node] = True
        prefix += weights[node]
        ranks[node] = prefix
        count += 1
        node = successors[node]
    if count != n or not all(visited):
        return -1, b""
    if output_is_null or capacity is not None and capacity < 8 * n:
        return -2, b""
    output = b"".join(struct.pack("<q", rank) for rank in ranks)
    return len(output), output
