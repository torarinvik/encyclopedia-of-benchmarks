"""Segment-tree rolling-hash reference for bounded dynamic substring queries."""

from __future__ import annotations

from collections.abc import Sequence

MAX_LENGTH = 20
MAX_OPERATIONS = 20
BASE = 911_382_323
MODULUS = 1_000_000_007
MAX_VALID_INPUT_LENGTH = 2 + MAX_LENGTH + 5 * MAX_OPERATIONS
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
WORKSPACE_BYTES = 4096
MAX_RESULT = 4 * (MAX_OPERATIONS * (MAX_OPERATIONS + 1) // 2)
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1


def _decode(values: Sequence[int] | None, input_length: int | None,
            input_is_null: bool) -> tuple[int, list[int], list[tuple[int, int, int, int, int]]] | None:
    if type(input_is_null) is not bool or input_is_null:
        return None
    if not isinstance(values, (list, tuple)) or not 2 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH:
        return None
    if any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values):
        return None
    declared_length = len(values) if input_length is None else input_length
    if type(declared_length) is not int or declared_length != len(values):
        return None

    length, operation_count = values[:2]
    if not 0 <= length <= MAX_LENGTH or not 0 <= operation_count <= MAX_OPERATIONS:
        return None
    if len(values) != 2 + length + 5 * operation_count:
        return None
    symbols = list(values[2:2 + length])
    if any(not 0 <= symbol <= 25 for symbol in symbols):
        return None

    operations: list[tuple[int, int, int, int, int]] = []
    start = 2 + length
    for offset in range(start, len(values), 5):
        opcode, a, b, c, d = values[offset:offset + 5]
        if opcode == 0:
            if not 0 <= a < length or not 0 <= b <= 25 or c != 0 or d != 0:
                return None
        elif opcode == 1:
            if not (0 <= a <= b <= length and 0 <= c <= d <= length):
                return None
        else:
            return None
        operations.append((opcode, a, b, c, d))
    return length, symbols, operations


def expected_result(values: Sequence[int] | None, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    """Return the weighted update/comparison trace, or -1 for invalid input."""
    decoded = _decode(values, input_length, input_is_null)
    if decoded is None:
        return -1
    length, symbols, operations = decoded
    tree_size = 1
    while tree_size < length:
        tree_size *= 2
    tree = [(0, 0)] * (2 * tree_size)
    for index, symbol in enumerate(symbols):
        tree[tree_size + index] = (symbol, 1)

    powers = [1]
    for _ in range(length):
        powers.append((powers[-1] * BASE) % MODULUS)

    def combine(left: tuple[int, int], right: tuple[int, int]) -> tuple[int, int]:
        return ((left[0] * powers[right[1]] + right[0]) % MODULUS,
                left[1] + right[1])

    for node in range(tree_size - 1, 0, -1):
        tree[node] = combine(tree[2 * node], tree[2 * node + 1])

    def range_hash(left: int, right: int) -> tuple[int, int]:
        left += tree_size
        right += tree_size
        left_result = (0, 0)
        right_result = (0, 0)
        while left < right:
            if left & 1:
                left_result = combine(left_result, tree[left])
                left += 1
            if right & 1:
                right -= 1
                right_result = combine(tree[right], right_result)
            left //= 2
            right //= 2
        return combine(left_result, right_result)

    checksum = 0
    for index, (opcode, a, b, c, d) in enumerate(operations, start=1):
        response = 0
        if opcode == 0:
            symbols[a] = b
            node = tree_size + a
            tree[node] = (b, 1)
            node //= 2
            while node:
                tree[node] = combine(tree[2 * node], tree[2 * node + 1])
                node //= 2
        else:
            left_hash = range_hash(a, b)
            right_hash = range_hash(c, d)
            response = int(left_hash == right_hash)
        checksum += index * (opcode * 2 + response + 1)
    return checksum
