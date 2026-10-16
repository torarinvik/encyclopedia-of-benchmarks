"""Independent scalar oracle for the pinned Java cuckoo hash map."""

from __future__ import annotations

OFFSET = 14695981039346656037
PRIME = 1099511628211
MASK64 = (1 << 64) - 1
MASK63 = (1 << 63) - 1
INT_MIN = -(1 << 31)
INT_MAX = (1 << 31) - 1
MAX_KEYS = 128
MAX_INPUT = MAX_KEYS + 2


def _trunc_div(value: int, divisor: int) -> int:
    quotient = abs(value) // divisor
    return -quotient if value < 0 else quotient


def _hash1(key: int, capacity: int) -> int:
    return key % capacity


def _hash2(key: int, capacity: int) -> int:
    quotient = _trunc_div(key, capacity)
    return quotient % capacity


def _record_hash(record: list[int]) -> int:
    digest = OFFSET
    for value in record:
        for byte in (value & MASK64).to_bytes(8, "little"):
            digest = ((digest ^ byte) * PRIME) & MASK64
    return digest & MASK63


def expected_result(values: list[int] | tuple[int, ...]) -> int:
    if (not isinstance(values, (list, tuple)) or len(values) < 2 or
            len(values) > MAX_INPUT or
            any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                for value in values)):
        return -1
    capacity, count = values[:2]
    if (capacity < 16 or capacity > 256 or capacity & (capacity - 1) or
            count < 0 or count > MAX_KEYS or len(values) != count + 2):
        return -1
    keys = list(values[2:])
    if (any(key < INT_MIN or key > INT_MAX or key == INT_MIN for key in keys) or
            len(set(keys)) != count):
        return -1

    first_buckets = [_hash1(key, capacity) for key in keys]
    safe_distinct = len(set(first_buckets)) == count
    safe_single_relocation = (
        count == 2 and first_buckets[0] == first_buckets[1] and
        _hash2(keys[0], capacity) != first_buckets[0]
    )
    if not (safe_distinct or safe_single_relocation):
        return -1

    final_capacity = capacity
    if safe_distinct and count > 0 and count / capacity > 0.7:
        final_capacity *= 2

    if safe_single_relocation:
        indices = [_hash2(keys[0], capacity), first_buckets[1]]
    else:
        indices = [_hash1(key, final_capacity) for key in keys]
    return _record_hash([count, *indices])
