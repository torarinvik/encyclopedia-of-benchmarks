"""Independent sorted-set operation-trace oracle for the sorted-table contract."""

from __future__ import annotations

from collections.abc import Sequence

MAX_INITIAL_KEYS = 128
MAX_OPERATIONS = 256
MAX_SIZE = 256
MIN_KEY = -1_000_000
MAX_KEY = 1_000_000
MAX_PARSEABLE_INPUT_LENGTH = 899
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1
INVALID_RESULT = -1
HASH_MODULUS = 1_000_000_007


def _key_code(key: int) -> int:
    return key - MIN_KEY + 1


def _sequence_code(keys: Sequence[int]) -> int:
    rolling_hash = 0
    for key in keys:
        rolling_hash = (31 * rolling_hash + _key_code(key)) % HASH_MODULUS
    return len(keys) * HASH_MODULUS + rolling_hash


def expected_result(values: Sequence[int] | None) -> int:
    """Return the operation checksum, or -1 for invalid input or trace."""
    if (
        not isinstance(values, (list, tuple))
        or len(values) > MAX_PARSEABLE_INPUT_LENGTH
        or any(
            type(value) is not int or not I64_MIN <= value <= I64_MAX
            for value in values
        )
        or len(values) < 2
    ):
        return INVALID_RESULT

    initial_count = values[0]
    if not 0 <= initial_count <= MAX_INITIAL_KEYS:
        return INVALID_RESULT
    operation_count_index = initial_count + 1
    if operation_count_index >= len(values):
        return INVALID_RESULT

    items = list(values[1:operation_count_index])
    operation_count = values[operation_count_index]
    if not 0 <= operation_count <= MAX_OPERATIONS:
        return INVALID_RESULT
    if len(values) != operation_count_index + 1 + 3 * operation_count:
        return INVALID_RESULT
    if any(not MIN_KEY <= key <= MAX_KEY for key in items):
        return INVALID_RESULT
    if any(items[index - 1] >= items[index] for index in range(1, len(items))):
        return INVALID_RESULT

    checksum = 0
    operations_start = operation_count_index + 1
    for operation_index in range(operation_count):
        opcode, first, second = values[
            operations_start + 3 * operation_index : operations_start + 3 * operation_index + 3
        ]
        observed: int | None

        if opcode == 0:  # find
            if second != 0 or not MIN_KEY <= first <= MAX_KEY:
                return INVALID_RESULT
            observed = _key_code(first) if first in items else 0
        elif opcode == 1:  # has
            if second != 0 or not MIN_KEY <= first <= MAX_KEY:
                return INVALID_RESULT
            observed = int(first in items)
        elif opcode == 2:  # min
            if first != 0 or second != 0:
                return INVALID_RESULT
            observed = _key_code(items[0]) if items else 0
        elif opcode == 3:  # max
            if first != 0 or second != 0:
                return INVALID_RESULT
            observed = _key_code(items[-1]) if items else 0
        elif opcode == 4:  # strict successor
            if second != 0 or not MIN_KEY <= first <= MAX_KEY:
                return INVALID_RESULT
            successor = next((key for key in items if key > first), None)
            observed = _key_code(successor) if successor is not None else 0
        elif opcode == 5:  # strict predecessor
            if second != 0 or not MIN_KEY <= first <= MAX_KEY:
                return INVALID_RESULT
            predecessor = next((key for key in reversed(items) if key < first), None)
            observed = _key_code(predecessor) if predecessor is not None else 0
        elif opcode == 6:  # insert, optional upsert
            if not MIN_KEY <= first <= MAX_KEY or second not in (0, 1):
                return INVALID_RESULT
            existing = first if first in items else None
            if existing is None:
                if len(items) >= MAX_SIZE:
                    return INVALID_RESULT
                items.append(first)
                items.sort()
            elif second == 1:
                items[items.index(existing)] = first
            observed = _key_code(existing) if existing is not None else 0
        elif opcode == 7:  # remove one matching key
            if second != 0 or not MIN_KEY <= first <= MAX_KEY:
                return INVALID_RESULT
            if first in items:
                items.remove(first)
                observed = _key_code(first)
            else:
                observed = 0
        elif opcode == 8:  # inclusive ascending range
            if not MIN_KEY <= first <= MAX_KEY or not MIN_KEY <= second <= MAX_KEY:
                return INVALID_RESULT
            selected = [key for key in items if first <= key <= second]
            observed = _sequence_code(selected)
        elif opcode == 9:  # inclusive descending range
            if not MIN_KEY <= first <= MAX_KEY or not MIN_KEY <= second <= MAX_KEY:
                return INVALID_RESULT
            selected = [key for key in reversed(items) if first <= key <= second]
            observed = _sequence_code(selected)
        elif opcode == 10:  # all ascending
            if first != 0 or second != 0:
                return INVALID_RESULT
            observed = _sequence_code(items)
        elif opcode == 11:  # all descending
            if first != 0 or second != 0:
                return INVALID_RESULT
            observed = _sequence_code(list(reversed(items)))
        elif opcode == 12:  # empty
            if first != 0 or second != 0:
                return INVALID_RESULT
            observed = int(not items)
        elif opcode == 13:  # clear
            if first != 0 or second != 0:
                return INVALID_RESULT
            items.clear()
            observed = None
        else:
            return INVALID_RESULT

        if observed is not None:
            checksum += (operation_index + 1) * (observed + 1)

    for position, key in enumerate(items, start=1):
        checksum += (operation_count + position) * _key_code(key)
    return checksum
