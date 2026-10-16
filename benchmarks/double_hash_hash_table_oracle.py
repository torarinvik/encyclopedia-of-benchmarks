"""Independent oracle for the bounded double-hash table operation stream."""

from __future__ import annotations

I64_MIN, I64_MAX = -(2**63), 2**63 - 1
MAX_INPUT_LENGTH = 2 + 2 * 512


def is_prime(value: int) -> bool:
    if value < 2:
        return False
    divisor = 2
    while divisor * divisor <= value:
        if value % divisor == 0:
            return False
        divisor += 1
    return True


def oracle(values: list[int]) -> int:
    if not isinstance(values, list) or len(values) < 2:
        return -1
    if any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values):
        return -1
    capacity, operation_count = values[:2]
    if not 3 <= capacity <= 101 or not is_prime(capacity):
        return -1
    if not 0 <= operation_count <= 512 or len(values) != 2 + 2 * operation_count:
        return -1
    operations = [(values[2 + 2 * i], values[3 + 2 * i])
                  for i in range(operation_count)]
    if any(op not in (1, 2, 3) for op, _ in operations):
        return -1
    # None is EMPTY, a unique object is TOMBSTONE, and integers are occupied keys.
    tombstone = object()
    table: list[object | int | None] = [None] * capacity
    successes = 0
    for operation, key in operations:
        first = key % capacity
        step = 1 + key % (capacity - 1)
        if operation == 1:
            first_tombstone = -1
            inserted = False
            for probe in range(capacity):
                index = (first + probe * step) % capacity
                slot = table[index]
                if slot == key:
                    break
                if slot is tombstone:
                    if first_tombstone < 0:
                        first_tombstone = index
                elif slot is None:
                    table[first_tombstone if first_tombstone >= 0 else index] = key
                    inserted = True
                    break
            else:
                if first_tombstone >= 0:
                    table[first_tombstone] = key
                    inserted = True
            successes += int(inserted)
        else:
            found = -1
            for probe in range(capacity):
                index = (first + probe * step) % capacity
                slot = table[index]
                if slot is None:
                    break
                if slot is not tombstone and slot == key:
                    found = index
                    break
            if found >= 0:
                successes += 1
                if operation == 3:
                    table[found] = tombstone
    return successes
