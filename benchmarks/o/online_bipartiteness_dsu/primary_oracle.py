"""Incremental bipartiteness using DSU parent-edge parity and bad flags."""

from __future__ import annotations

I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1
MAX_N = 32
MAX_Q = 64
MAX_VALID_INPUT_LENGTH = 2 + 3 * MAX_Q
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1


def _decode(values, input_is_null=False, input_length=None):
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (tuple, list))
            or len(values) > MAX_PARSEABLE_INPUT_LENGTH
            or any(type(value) is not int or not I64_MIN <= value <= I64_MAX
                   for value in values)):
        return None
    if input_length is not None and (type(input_length) is not int or input_length != len(values)):
        return None
    if len(values) < 2:
        return None
    n, q = values[:2]
    if not 1 <= n <= MAX_N or not 0 <= q <= MAX_Q or len(values) != 2 + 3 * q:
        return None
    operations = []
    for j in range(q):
        opcode, first, second = values[2 + 3 * j: 5 + 3 * j]
        if opcode == 0:
            if not 0 <= first < n or not 0 <= second < n:
                return None
        elif opcode == 1:
            if not 0 <= first < n or second != 0:
                return None
        else:
            return None
        operations.append((opcode, first, second))
    return n, tuple(operations)


def _find(parent: list[int], parity: list[int], node: int) -> tuple[int, int]:
    root = node
    total = 0
    while parent[root] != root:
        total ^= parity[root]
        root = parent[root]
    accumulated = 0
    current = node
    while parent[current] != current:
        following = parent[current]
        edge_parity = parity[current]
        parent[current] = root
        parity[current] = total ^ accumulated
        accumulated ^= edge_parity
        current = following
    return root, total


def expected_result(values, input_is_null=False, input_length=None) -> int:
    decoded = _decode(values, input_is_null, input_length)
    if decoded is None:
        return -1
    n, operations = decoded
    parent = list(range(n))
    size = [1] * n
    parity = [0] * n
    bad = [False] * n
    checksum = 0
    query_ordinal = 0
    for opcode, first, second in operations:
        if opcode == 1:
            root, _ = _find(parent, parity, first)
            answer = 0 if bad[root] else 1
            checksum += (query_ordinal + 1) * (answer + 1)
            query_ordinal += 1
            continue
        root_a, parity_a = _find(parent, parity, first)
        root_b, parity_b = _find(parent, parity, second)
        if root_a == root_b:
            if parity_a == parity_b:
                bad[root_a] = True
            continue
        if size[root_a] < size[root_b]:
            root_a, root_b = root_b, root_a
            parity_a, parity_b = parity_b, parity_a
        parent[root_b] = root_a
        parity[root_b] = parity_a ^ parity_b ^ 1
        size[root_a] += size[root_b]
        bad[root_a] = bad[root_a] or bad[root_b]
    return checksum
