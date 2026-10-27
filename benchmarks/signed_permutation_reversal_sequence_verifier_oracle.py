"""Independent distance-table self-reduction oracle for DOI 384."""

from __future__ import annotations

import struct
from collections import deque
from collections.abc import Sequence

MAX_N = 5
MAX_INPUT_LENGTH = MAX_N + 2
MAX_MOVES = 2 * MAX_N
MAX_OUTPUT_BYTES = 8 * (1 + 2 * MAX_MOVES)


def _factorials(n: int) -> list[int]:
    result = [1]
    for value in range(1, n + 1):
        result.append(result[-1] * value)
    return result


def _state(permutation: Sequence[int]) -> int:
    rank = 0
    signs = 0
    absolute = [abs(value) for value in permutation]
    n = len(absolute)
    for i, value in enumerate(absolute):
        smaller_after = sum(1 for other in absolute[i + 1:] if other < value)
        rank = rank * (n - i) + smaller_after
        if permutation[i] < 0:
            signs |= 1 << (value - 1)
    return rank * (1 << n) + signs


def _permutation(state: int, n: int, factorials: Sequence[int]) -> list[int]:
    rank, signs = divmod(state, 1 << n)
    remaining = list(range(1, n + 1))
    permutation = []
    for i in range(n):
        block = factorials[n - i - 1]
        index, rank = divmod(rank, block)
        item = remaining.pop(index)
        permutation.append(-item if (signs >> (item - 1)) & 1 else item)
    return permutation


def _reversed(permutation: Sequence[int], left: int, right: int) -> list[int]:
    return list(permutation[:left]) + [-value for value in reversed(permutation[left:right + 1])] + list(permutation[right + 1:])


def _distance_table(n: int) -> tuple[list[int], list[int]]:
    factorials = _factorials(n)
    count = factorials[n] * (1 << n)
    distance = [-1] * count
    queue = deque([0])
    distance[0] = 0
    while queue:
        current = queue.popleft()
        permutation = _permutation(current, n, factorials)
        for left in range(n):
            for right in range(left, n):
                neighbor = _state(_reversed(permutation, left, right))
                if distance[neighbor] < 0:
                    distance[neighbor] = distance[current] + 1
                    queue.append(neighbor)
    return distance, factorials


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
    if sorted(abs(value) for value in permutation) != list(range(1, n + 1)):
        return None
    return permutation


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    invalid, output_error = -1, -2
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or capacity is not None and (type(capacity) is not int or capacity < 0)
            or input_length is not None and (type(input_length) is not int
                                             or not 0 <= input_length <= MAX_INPUT_LENGTH)
            or input_is_null and values not in (None, [], ())
            or not input_is_null and values is not None and input_length is not None
            and input_length != len(values)):
        return invalid, b""
    if input_is_null or values is None:
        return invalid, b""
    permutation = _decode(values)
    if permutation is None:
        return invalid, b""

    n = len(permutation)
    distance, factorials = _distance_table(n)
    current = _state(permutation)
    moves: list[tuple[int, int]] = []
    while distance[current] > 0:
        state_permutation = _permutation(current, n, factorials)
        selected = None
        for left in range(n):
            for right in range(left, n):
                next_permutation = _reversed(state_permutation, left, right)
                candidate = _state(next_permutation)
                if distance[candidate] == distance[current] - 1:
                    selected = (candidate, left + 1, right + 1)
                    break
            if selected is not None:
                break
        if selected is None:
            return invalid, b""
        current, left, right = selected
        moves.append((left, right))
        if len(moves) > MAX_MOVES:
            return invalid, b""

    result_values = [len(moves)]
    for left, right in moves:
        result_values.extend((left, right))
    payload = struct.pack("<" + "q" * len(result_values), *result_values)
    if output_is_null or capacity is not None and capacity < len(payload):
        return output_error, b""
    return len(payload), payload
