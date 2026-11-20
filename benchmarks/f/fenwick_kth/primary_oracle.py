"""Fenwick binary-lifting reference for one-based frequency selection."""

from __future__ import annotations

from collections.abc import Sequence

MAX_N = 64
MAX_Q = 32
MAX_FREQUENCY = 1_000_000
MAX_DELTA = 1_000_000
MAX_INPUT_LENGTH = 2 + MAX_N + 3 * MAX_Q + 1
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1


def _decode(values: Sequence[int] | None, input_length: int | None,
            input_is_null: bool) -> tuple[list[int], list[tuple[int, int, int]]] | None:
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple))
            or not 3 <= len(values) <= MAX_INPUT_LENGTH
            or any(type(value) is not int or not I64_MIN <= value <= I64_MAX
                   for value in values)):
        return None
    if input_length is not None and (
            type(input_length) is not int or input_length != len(values)):
        return None
    n, q = values[0], values[1]
    if not 1 <= n <= MAX_N or not 0 <= q <= MAX_Q:
        return None
    if len(values) != 2 + n + 3 * q:
        return None
    frequencies = list(values[2:2 + n])
    if any(not 0 <= frequency <= MAX_FREQUENCY for frequency in frequencies):
        return None
    operations: list[tuple[int, int, int]] = []
    cursor = 2 + n
    for _ in range(q):
        opcode, first, second = values[cursor:cursor + 3]
        cursor += 3
        if opcode == 0:
            if (not 0 <= first < n or not -MAX_DELTA <= second <= MAX_DELTA
                    or not 0 <= frequencies[first] + second <= MAX_FREQUENCY):
                return None
            frequencies[first] += second
        elif opcode == 1:
            if second != 0:
                return None
        else:
            return None
        operations.append((opcode, first, second))
    return list(values[2:2 + n]), operations


def _build(frequencies: list[int]) -> list[int]:
    n = len(frequencies)
    tree = [0] * (n + 1)
    for index, frequency in enumerate(frequencies, 1):
        tree[index] += frequency
        parent = index + (index & -index)
        if parent <= n:
            tree[parent] += tree[index]
    return tree


def _select(tree: list[int], rank: int) -> int:
    n = len(tree) - 1
    total = 0
    cursor = n
    while cursor:
        total += tree[cursor]
        cursor -= cursor & -cursor
    if rank <= 0 or rank > total:
        return -1
    index = 0
    step = 1 << (n.bit_length() - 1)
    while step:
        candidate = index + step
        if candidate <= n and tree[candidate] < rank:
            index = candidate
            rank -= tree[candidate]
        step >>= 1
    return index


def expected_output(values: Sequence[int] | None, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    decoded = _decode(values, input_length, input_is_null)
    if decoded is None:
        return -1
    frequencies, operations = decoded
    tree = _build(frequencies)
    n = len(frequencies)
    query_number = 0
    result = 0
    for opcode, first, second in operations:
        if opcode == 0:
            index = first + 1
            while index <= n:
                tree[index] += second
                index += index & -index
        else:
            answer = _select(tree, first)
            result += (query_number + 1) * (answer + 1)
            query_number += 1
    return result
