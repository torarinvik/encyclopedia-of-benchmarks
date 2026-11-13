"""Persistent prefix-histogram oracle for range kth-smallest queries."""

from __future__ import annotations

MAX_N = 32
MAX_Q = 32
VALUE_MIN = -1000
VALUE_MAX = 1000
MAX_VALID_INPUT_LENGTH = 130
MAX_PARSEABLE_INPUT_LENGTH = 131
MAX_NODES = 193
WORKSPACE_BYTES = 4096
INVALID_RESULT = -(1 << 63)


def _parse(values, input_is_null=False, input_length=None):
    if input_is_null or not isinstance(values, (list, tuple)):
        return None
    if (not 2 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return None
    if input_length is not None and (
        type(input_length) is not int or input_length != len(values)
    ):
        return None
    n, q = values[0], values[1]
    if not 1 <= n <= MAX_N or not 0 <= q <= MAX_Q:
        return None
    if len(values) != 2 + n + 3 * q:
        return None
    sequence = values[2:2 + n]
    if any(value < VALUE_MIN or value > VALUE_MAX for value in sequence):
        return None
    queries = []
    offset = 2 + n
    for query_index in range(q):
        left, right, k = values[offset + 3 * query_index:offset + 3 * query_index + 3]
        if not (0 <= left <= right < n and 1 <= k <= right - left + 1):
            return None
        queries.append((left, right, k))
    return sequence, queries


def expected_result(values, input_is_null=False, input_length=None):
    """Return the weighted query checksum, or INT64_MIN for malformed input."""
    parsed = _parse(values, input_is_null=input_is_null, input_length=input_length)
    if parsed is None:
        return INVALID_RESULT
    sequence, queries = parsed
    coordinates = sorted(set(sequence))
    left_child = [0]
    right_child = [0]
    count = [0]
    roots = [0]

    def clone(previous: int) -> int:
        node = len(count)
        left_child.append(left_child[previous])
        right_child.append(right_child[previous])
        count.append(count[previous] + 1)
        return node

    for value in sequence:
        rank = _lower_bound(coordinates, value)
        previous = roots[-1]
        root = clone(previous)
        old_node, new_node = previous, root
        lo, hi = 0, len(coordinates)
        while hi - lo > 1:
            middle = (lo + hi) // 2
            if rank < middle:
                old_child = left_child[old_node]
                new_child = clone(old_child)
                left_child[new_node] = new_child
                old_node, new_node = old_child, new_child
                hi = middle
            else:
                old_child = right_child[old_node]
                new_child = clone(old_child)
                right_child[new_node] = new_child
                old_node, new_node = old_child, new_child
                lo = middle
        roots.append(root)

    checksum = 0
    for query_index, (left, right, k) in enumerate(queries):
        before, after = roots[left], roots[right + 1]
        lo, hi = 0, len(coordinates)
        while hi - lo > 1:
            middle = (lo + hi) // 2
            left_count = count[left_child[after]] - count[left_child[before]]
            if k <= left_count:
                before, after = left_child[before], left_child[after]
                hi = middle
            else:
                k -= left_count
                before, after = right_child[before], right_child[after]
                lo = middle
        checksum += (query_index + 1) * coordinates[lo]
    return checksum


def _lower_bound(values: list[int], target: int) -> int:
    lo, hi = 0, len(values)
    while lo < hi:
        middle = (lo + hi) // 2
        if values[middle] < target:
            lo = middle + 1
        else:
            hi = middle
    return lo
