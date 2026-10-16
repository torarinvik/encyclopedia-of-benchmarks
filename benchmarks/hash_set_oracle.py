"""Oracle for the bounded, deterministic C hash-set benchmark."""

from __future__ import annotations

MAX_IDS = 64
CAPACITY = 1024
MAX_INPUT_LENGTH = 2 + 2 * MAX_IDS
MIN_I64 = -(1 << 63)
MAX_I64 = (1 << 63) - 1
FNV_OFFSET_BASIS = 14695981039346656037
FNV_PRIME = 1099511628211
MASK_64 = (1 << 64) - 1
MASK_63 = (1 << 63) - 1


def _bucket_for_id(identifier: int) -> int:
    """Compute the source Adler-32 hash and its power-of-two bucket index."""
    a = 1
    b = 0
    for byte in f"key{identifier}".encode("ascii"):
        a = (a + byte) % 65521
        b = (b + a) % 65521
    value = (b << 16) | a
    return (CAPACITY - 1) & (value ^ (value >> 12))


def _fnv_word(hash_value: int, word: int) -> int:
    bits = word & MASK_64
    for shift in range(0, 64, 8):
        hash_value ^= (bits >> shift) & 0xFF
        hash_value = (hash_value * FNV_PRIME) & MASK_64
    return hash_value


def expected_result(values: list[int] | tuple[int, ...]) -> int:
    """Return the low-63-bit membership trace hash, or -1 for invalid input."""
    if not isinstance(values, (list, tuple)) or len(values) < 2 or len(values) > MAX_INPUT_LENGTH:
        return -1
    if any(type(value) is not int or not MIN_I64 <= value <= MAX_I64 for value in values):
        return -1

    add_count = values[0]
    if not 0 <= add_count <= MAX_IDS:
        return -1
    query_count_index = 1 + add_count
    if query_count_index >= len(values):
        return -1
    query_count = values[query_count_index]
    if not 0 <= query_count <= MAX_IDS or len(values) != 2 + add_count + query_count:
        return -1

    add_ids = values[1:query_count_index]
    query_ids = values[query_count_index + 1 :]
    if any(not 0 <= identifier < MAX_IDS for identifier in (*add_ids, *query_ids)):
        return -1

    slots = [-1] * CAPACITY
    set_length = 0
    for identifier in add_ids:
        bucket = _bucket_for_id(identifier)
        occupant = slots[bucket]
        if occupant == -1:
            slots[bucket] = identifier
            set_length += 1
        elif occupant != identifier:
            # This cannot occur for the documented key set; it guards the ABI.
            return -1

    trace = [set_length]
    for identifier in query_ids:
        trace.append(int(slots[_bucket_for_id(identifier)] == identifier))

    result = FNV_OFFSET_BASIS
    for word in trace:
        result = _fnv_word(result, word)
    return result & MASK_63
