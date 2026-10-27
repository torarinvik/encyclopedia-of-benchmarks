"""Bounded exact self-reduction for signed reversal sorting (DOI 384)."""

from __future__ import annotations

import struct
from collections import deque
from collections.abc import Sequence

MAX_N = 5
MAX_INPUT_LENGTH = MAX_N + 2
MAX_MOVES = 2 * MAX_N
MAX_OUTPUT_BYTES = 8 * (1 + 2 * MAX_MOVES)
MAX_STATES = 1
for _factor in range(1, MAX_N + 1):
    MAX_STATES *= _factor
MAX_STATES *= 1 << MAX_N
MAX_WORKSPACE_BYTES = 65536
INVALID_RESULT = -1
OUTPUT_ERROR = -2


def _factorials(n: int) -> list[int]:
    result = [1] * (n + 1)
    for value in range(1, n + 1):
        result[value] = result[value - 1] * value
    return result


def _rank_permutation(values: Sequence[int]) -> int:
    n = len(values)
    rank = 0
    for index, value in enumerate(values):
        smaller = sum(other < value for other in values[index + 1 :])
        rank = rank * (n - index) + smaller
    return rank


def _encode(values: Sequence[int]) -> int:
    n = len(values)
    signs = 0
    absolute = []
    for value in values:
        item = abs(value)
        absolute.append(item)
        if value < 0:
            signs |= 1 << (item - 1)
    return _rank_permutation(absolute) * (1 << n) + signs


def _decode_state(state: int, n: int, factorials: Sequence[int]) -> list[int]:
    sign_count = 1 << n
    rank, signs = divmod(state, sign_count)
    available = list(range(1, n + 1))
    result = []
    for index in range(n):
        factor = factorials[n - index - 1]
        digit, rank = divmod(rank, factor)
        value = available.pop(digit)
        result.append(-value if signs & (1 << (value - 1)) else value)
    return result


def _reverse(values: list[int], left: int, right: int) -> None:
    while left < right:
        values[left], values[right] = -values[right], -values[left]
        left += 1
        right -= 1
    if left == right:
        values[left] = -values[left]


def _shortest_sequence(values: Sequence[int]) -> list[tuple[int, int]]:
    """BFS shortest path; ascending interval order fixes self-reduction ties."""
    n = len(values)
    factorials = _factorials(n)
    state_count = factorials[n] * (1 << n)
    start = _encode(values)
    if start == 0:
        return []

    parent = [-2] * state_count
    parent_move = [(-1, -1)] * state_count
    queue = deque([start])
    parent[start] = -1
    while queue and parent[0] == -2:
        state = queue.popleft()
        permutation = _decode_state(state, n, factorials)
        for left in range(n):
            for right in range(left, n):
                neighbor = permutation.copy()
                _reverse(neighbor, left, right)
                next_state = _encode(neighbor)
                if parent[next_state] != -2:
                    continue
                parent[next_state] = state
                parent_move[next_state] = (left + 1, right + 1)
                queue.append(next_state)
                if next_state == 0:
                    break
            if parent[0] != -2:
                break

    reversed_moves = []
    state = 0
    while parent[state] >= 0:
        reversed_moves.append(parent_move[state])
        state = parent[state]
    return list(reversed(reversed_moves))


def _decode(values: Sequence[int] | None) -> list[int] | None:
    if (not isinstance(values, (list, tuple)) or not 1 <= len(values) <= MAX_INPUT_LENGTH
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return None
    n = values[0]
    if not 2 <= n <= MAX_N or len(values) != n + 1:
        return None
    permutation = list(values[1:])
    if any(value == 0 or abs(value) > n for value in permutation):
        return None
    if {abs(value) for value in permutation} != set(range(1, n + 1)):
        return None
    return permutation


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or capacity is not None and (type(capacity) is not int or capacity < 0)
            or input_length is not None and (type(input_length) is not int
                                             or not 0 <= input_length <= MAX_INPUT_LENGTH)
            or input_is_null and values not in (None, [], ())
            or not input_is_null and values is not None and input_length is not None
            and input_length != len(values)):
        return INVALID_RESULT, b""
    if input_is_null or values is None:
        return INVALID_RESULT, b""
    permutation = _decode(values)
    if permutation is None:
        return INVALID_RESULT, b""
    moves = _shortest_sequence(permutation)
    if len(moves) > MAX_MOVES:
        return INVALID_RESULT, b""
    output_values = [len(moves)]
    for left, right in moves:
        output_values.extend((left, right))
    payload = struct.pack("<" + "q" * len(output_values), *output_values)
    if output_is_null or capacity is not None and capacity < len(payload):
        return OUTPUT_ERROR, b""
    return len(payload), payload
