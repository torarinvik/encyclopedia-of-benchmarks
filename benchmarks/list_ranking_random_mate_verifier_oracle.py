"""Direct linked-list traversal verifier for bounded Random_Mate frames."""

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
    if not 1 <= n <= MAX_N or not 0 <= head < n or actual_length < 3 + 2 * n:
        return None
    weights = list(values[2:2 + n])
    successors = list(values[2 + n:2 + 2 * n])
    rounds = values[2 + 2 * n]
    if not 0 <= rounds <= MAX_ROUNDS or actual_length != 3 + 2 * n + rounds * n:
        return None
    if any(not 1 <= weight <= 10000 for weight in weights):
        return None
    if any(target < -1 or target >= n for target in successors):
        return None
    coins = values[3 + 2 * n:]
    if any(coin not in (0, 1) for coin in coins):
        return None

    predecessor = [-1] * n
    tails = 0
    for node, target in enumerate(successors):
        if target == -1:
            tails += 1
        else:
            if predecessor[target] != -1:
                return None
            predecessor[target] = node
    if tails != 1 or predecessor[head] != -1:
        return None
    path = []
    visited = [False] * n
    node = head
    while node != -1:
        if visited[node]:
            return None
        visited[node] = True
        path.append(node)
        node = successors[node]
    if len(path) != n:
        return None
    return n, head, weights, successors, rounds, coins, path


def _tape_reaches_one(path: list[int], rounds: int, coins: Sequence[int]) -> bool:
    """Check only whether the supplied synchronous tape reaches one node."""
    active_path = path[:]
    n = len(path)
    for round_index in range(rounds):
        if len(active_path) == 1:
            return True
        row = coins[round_index * n:(round_index + 1) * n]
        removed: set[int] = set()
        for current, target in zip(active_path, active_path[1:]):
            if row[current] == 0 and row[target] == 1:
                removed.add(target)
        active_path = [node for node in active_path if node not in removed]
    return len(active_path) == 1


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
    n, _, weights, _, rounds, coins, path = parsed
    if not _tape_reaches_one(path, rounds, coins):
        return -1, b""
    if output_is_null or capacity is not None and capacity < 8 * n:
        return -2, b""
    suffix = 0
    ranks = [0] * n
    for node in reversed(path):
        suffix += weights[node]
        ranks[node] = suffix
    output = b"".join(struct.pack("<q", rank) for rank in ranks)
    return len(output), output
