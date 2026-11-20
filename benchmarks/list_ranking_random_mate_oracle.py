"""Random-mate contraction oracle for a bounded list-ranking profile."""

from __future__ import annotations

import struct
from collections.abc import Sequence

MAX_N = 8
MAX_ROUNDS = 32
MAX_INPUT_LENGTH = 3 + 2 * MAX_N + MAX_ROUNDS * MAX_N
MAX_OUTPUT_BYTES = 8 * MAX_N


def _parse(values: Sequence[int] | None, *, input_is_null: bool,
           input_length: int | None):
    if input_is_null or values is None or not isinstance(values, (list, tuple)):
        return None
    actual_length = len(values)
    if input_length is not None and input_length != actual_length:
        return None
    if actual_length < 5 or actual_length > MAX_INPUT_LENGTH or any(
            type(value) is not int or not -(1 << 63) <= value < (1 << 63)
            for value in values):
        return None
    n, head = values[0], values[1]
    if not 1 <= n <= MAX_N or not 0 <= head < n:
        return None
    if actual_length < 3 + 2 * n:
        return None
    weight = list(values[2:2 + n])
    successor = list(values[2 + n:2 + 2 * n])
    rounds = values[2 + 2 * n]
    if not 0 <= rounds <= MAX_ROUNDS or actual_length != 3 + 2 * n + rounds * n:
        return None
    if any(not 1 <= value <= 10000 for value in weight):
        return None
    if any(value < -1 or value >= n for value in successor):
        return None
    coins = values[3 + 2 * n:]
    if any(value not in (0, 1) for value in coins):
        return None

    indegree = [0] * n
    for target in successor:
        if target >= 0:
            indegree[target] += 1
            if indegree[target] > 1:
                return None
    if indegree[head] != 0 or sum(target == -1 for target in successor) != 1:
        return None
    visited = [False] * n
    path = []
    node = head
    while node != -1:
        if visited[node]:
            return None
        visited[node] = True
        path.append(node)
        node = successor[node]
    if len(path) != n:
        return None
    return n, head, weight, successor, rounds, coins


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or capacity is not None and (type(capacity) is not int or capacity < 0)
            or input_length is not None and
            (type(input_length) is not int or not 0 <= input_length <= MAX_INPUT_LENGTH)
            or input_is_null and values not in (None, [], ())
            or not input_is_null and values is not None and input_length is not None
            and isinstance(values, (list, tuple)) and input_length != len(values)):
        return -1, b""
    parsed = _parse(values, input_is_null=input_is_null, input_length=input_length)
    if parsed is None:
        return -1, b""
    n, head, weights, successor, rounds, coins = parsed

    active = [True] * n
    removal_round = [-1] * n
    for round_index in range(rounds):
        if successor[head] == -1:
            break
        old_successor = successor[:]
        old_weight = weights[:]
        remove = [False] * n
        coin_offset = round_index * n
        for node in range(n):
            target = old_successor[node]
            if (active[node] and target != -1 and coins[coin_offset + node] == 0
                    and coins[coin_offset + target] == 1):
                remove[target] = True
                removal_round[target] = round_index
        for node in range(n):
            target = old_successor[node]
            if active[node] and target != -1 and remove[target]:
                weights[node] = old_weight[node] + old_weight[target]
                successor[node] = old_successor[target]
        for node in range(n):
            if remove[node]:
                active[node] = False

    if successor[head] != -1:
        return -1, b""
    if output_is_null or capacity is not None and capacity < 8 * n:
        return -2, b""
    ranks = weights[:]
    for round_index in range(rounds - 1, -1, -1):
        for node in range(n):
            if removal_round[node] == round_index:
                target = successor[node]
                if target != -1:
                    ranks[node] += ranks[target]
    output = b"".join(struct.pack("<q", rank) for rank in ranks)
    return len(output), output
