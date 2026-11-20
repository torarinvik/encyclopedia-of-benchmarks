"""Union-by-size DSU with circular member lists."""

from __future__ import annotations

from collections.abc import Sequence

MAX_ITEMS = 16
MAX_OPERATIONS = 32
MAX_VALID_INPUT_LENGTH = 98
MAX_PARSEABLE_INPUT_LENGTH = 99
INVALID_RESULT = -1


def _decode(values: Sequence[int] | None, input_is_null: bool,
            input_length: int | None) -> tuple[int, list[tuple[int, int, int]]] | None:
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple))
            or len(values) < 2 or len(values) > MAX_PARSEABLE_INPUT_LENGTH
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return None
    if input_length is not None and (
            type(input_length) is not int or input_length != len(values)):
        return None
    item_count, operation_count = values[:2]
    if not 1 <= item_count <= MAX_ITEMS or not 0 <= operation_count <= MAX_OPERATIONS:
        return None
    if len(values) != 2 + 3 * operation_count or len(values) > MAX_VALID_INPUT_LENGTH:
        return None
    operations: list[tuple[int, int, int]] = []
    for position in range(2, len(values), 3):
        opcode, first, second = values[position:position + 3]
        if opcode == 0:
            if not 0 <= first < item_count or not 0 <= second < item_count:
                return None
        elif opcode == 1:
            if not 0 <= first < item_count or second != 0:
                return None
        else:
            return None
        operations.append((opcode, first, second))
    return item_count, operations


def expected_result(values: Sequence[int] | None, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    decoded = _decode(values, input_is_null, input_length)
    if decoded is None:
        return INVALID_RESULT
    item_count, operations = decoded
    parent = [-1] * item_count
    successor = list(range(item_count))

    def find(item: int) -> int:
        root = item
        while parent[root] >= 0:
            root = parent[root]
        while item != root:
            next_item = parent[item]
            parent[item] = root
            item = next_item
        return root

    checksum = 0
    for ordinal, (opcode, first, second) in enumerate(operations, start=1):
        if opcode == 0:
            left = find(first)
            right = find(second)
            merged = 0
            if left != right:
                if parent[left] > parent[right]:
                    left, right = right, left
                parent[left] += parent[right]
                parent[right] = left
                successor[left], successor[right] = successor[right], successor[left]
                merged = 1
            observed = merged
        else:
            mask = 0
            item = first
            while True:
                mask |= 1 << item
                item = successor[item]
                if item == first:
                    break
            observed = mask
        checksum += ordinal * (observed + 1)
    return checksum
