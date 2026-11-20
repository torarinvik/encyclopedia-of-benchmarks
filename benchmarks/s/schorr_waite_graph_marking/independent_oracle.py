"""Queue-based reachability oracle for bounded ordered binary graphs."""

from __future__ import annotations

from collections import deque

from .primary_oracle import (
    I64_MAX,
    I64_MIN,
    MAX_NODES,
    MAX_PARSEABLE_INPUT_LENGTH,
    MIN_NODES,
)


def _decode(values, input_is_null: bool, input_length: int | None):
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (tuple, list))
            or len(values) > MAX_PARSEABLE_INPUT_LENGTH
            or any(type(value) is not int or not I64_MIN <= value <= I64_MAX
                   for value in values)):
        return None
    if input_length is not None and (
            type(input_length) is not int or input_length != len(values)):
        return None
    if len(values) < 2 or not MIN_NODES <= values[0] <= MAX_NODES:
        return None
    count, root = values[:2]
    if not 0 <= root < count or len(values) != 2 + 2 * count:
        return None
    edges = []
    for node in range(count):
        pair = tuple(values[2 + 2 * node:4 + 2 * node])
        if any(child != -1 and not 0 <= child < count for child in pair):
            return None
        edges.append(pair)
    return count, root, edges


def expected_result(values, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    decoded = _decode(values, input_is_null, input_length)
    if decoded is None:
        return -1
    count, root, edges = decoded
    pending = deque([root])
    reachable = 0
    while pending:
        node = pending.popleft()
        bit = 1 << node
        if reachable & bit:
            continue
        reachable |= bit
        pending.extend(child for child in edges[node] if child != -1)
    return reachable
