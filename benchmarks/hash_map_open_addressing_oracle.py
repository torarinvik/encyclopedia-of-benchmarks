"""Independent oracle for the bounded Python open-addressing hash map trace."""

from __future__ import annotations

I64_MIN, I64_MAX = -(2**63), 2**63 - 1
MAX_OPERATIONS = 256
MAX_INPUT_LENGTH = 1 + 3 * MAX_OPERATIONS
MAX_KEY = 1_000_000
MAX_VALUE = 1_000_000
VALUE_OFFSET = MAX_VALUE + 1

_EMPTY = object()
_DELETED = object()


def _insert_without_growth(table: list[object], key: int, value: int) -> int:
    """Reinsert a live item during resize and return the resulting size."""
    capacity = len(table)
    index = key % capacity
    for _ in range(capacity):
        slot = table[index]
        if slot is _EMPTY or slot is _DELETED:
            table[index] = (key, value)
            return 1
        stored_key, _ = slot
        if stored_key == key:
            table[index] = (key, value)
            return 0
        index = (index + 1) % capacity
    return 0


def _resize(table: list[object], new_capacity: int) -> tuple[list[object], int]:
    new_table: list[object] = [_EMPTY] * new_capacity
    size = 0
    for slot in table:
        if slot is not _EMPTY and slot is not _DELETED:
            key, value = slot
            size += _insert_without_growth(new_table, key, value)
    return new_table, size


def _find(table: list[object], key: int) -> tuple[int | None, int | None]:
    """Return (matching slot, first tombstone) while respecting empty slots."""
    capacity = len(table)
    index = key % capacity
    first_deleted = None
    for _ in range(capacity):
        slot = table[index]
        if slot is _EMPTY:
            return None, first_deleted
        if slot is _DELETED:
            if first_deleted is None:
                first_deleted = index
        elif slot[0] == key:
            return index, first_deleted
        index = (index + 1) % capacity
    return None, first_deleted


def oracle(values: list[int]) -> int:
    if not isinstance(values, list) or not 1 <= len(values) <= MAX_INPUT_LENGTH:
        return -1
    if any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values):
        return -1
    operation_count = values[0]
    if not 0 <= operation_count <= MAX_OPERATIONS or len(values) != 1 + 3 * operation_count:
        return -1

    table: list[object] = [_EMPTY] * 8
    size = 0
    query_sum = 0
    query_index = 0

    for operation_index in range(operation_count):
        base = 1 + 3 * operation_index
        opcode, key, value = values[base:base + 3]
        if opcode not in (0, 1, 2, 3, 4):
            return -1
        if opcode == 0:
            if not 0 <= key <= MAX_KEY or not -MAX_VALUE <= value <= MAX_VALUE:
                return -1
            if size >= 64 and _find(table, key)[0] is None:
                return -1

            # The source checks fullness before probing, even for an update.
            if size >= int(len(table) * 0.75):
                table, size = _resize(table, len(table) * 2)

            found, first_deleted = _find(table, key)
            if found is not None and first_deleted is not None:
                # The pinned source treats a tombstone as falsy before testing
                # key equality, so this trace would create a duplicate key.
                return -1
            if found is not None:
                table[found] = (key, value)
            else:
                _, first_deleted = _find(table, key)
                capacity = len(table)
                index = key % capacity
                target = first_deleted
                for _ in range(capacity):
                    if table[index] is _EMPTY:
                        if target is None:
                            target = index
                        break
                    index = (index + 1) % capacity
                if target is None:
                    return -1
                table[target] = (key, value)
                size += 1
        elif opcode in (1, 2, 3):
            if not 0 <= key <= MAX_KEY or value != 0:
                return -1
            found, _ = _find(table, key)
            if opcode in (1, 2) and found is None:
                return -1
            if opcode == 1:
                answer = table[found][1]
                query_index += 1
                query_sum += query_index * (answer + VALUE_OFFSET)
            elif opcode == 2:
                table[found] = _DELETED
                size -= 1
                if len(table) > 8 and size < len(table) * 0.75 / 2:
                    table, size = _resize(table, len(table) // 2)
            else:
                query_index += 1
                query_sum += query_index * (int(found is not None) + VALUE_OFFSET)
        else:
            if key != 0 or value != 0:
                return -1
            query_index += 1
            query_sum += query_index * (size + VALUE_OFFSET)

    final_state = sum(
        ordinal * (key + 1) * (value + VALUE_OFFSET)
        for ordinal, (key, value) in enumerate(
            sorted(slot for slot in table if slot is not _EMPTY and slot is not _DELETED),
            start=1,
        )
    )
    return query_sum + final_state + size
