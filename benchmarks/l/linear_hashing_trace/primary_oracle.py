"""Linear-hashing bucket-split trace for the bounded integer-array profile."""

from __future__ import annotations

from collections.abc import Sequence

MAX_OPERATIONS = 63
MAX_VALID_INPUT_LENGTH = 1 + 2 * MAX_OPERATIONS
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
WORKSPACE_BYTES = 8192
MIN_KEY = -1024
MAX_KEY = 1023
MAX_BUCKETS = 32
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1


def _decode(values: Sequence[int] | None, input_length: int | None,
            input_is_null: bool) -> list[tuple[int, int]] | None:
    if type(input_is_null) is not bool or input_is_null:
        return None
    if not isinstance(values, (list, tuple)) or not 1 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH:
        return None
    if any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values):
        return None
    declared_length = len(values) if input_length is None else input_length
    if type(declared_length) is not int or declared_length != len(values):
        return None
    count = values[0]
    if not 0 <= count <= MAX_OPERATIONS or len(values) != 1 + 2 * count:
        return None
    operations: list[tuple[int, int]] = []
    for offset in range(1, len(values), 2):
        opcode, key = values[offset:offset + 2]
        if opcode not in (0, 1, 2) or not MIN_KEY <= key <= MAX_KEY:
            return None
        operations.append((opcode, key))
    return operations


def _bucket(key: int, level: int, split: int) -> int:
    base = 1 << level
    index = key % base
    return key % (base << 1) if index < split else index


def _split(head: list[int], keys: list[int], links: list[int],
           level: int, split: int) -> None:
    base = 1 << level
    old_bucket = split
    new_bucket = base + split
    current = head[old_bucket]
    head[old_bucket] = -1
    while current != -1:
        following = links[current]
        destination = keys[current] % (base << 1)
        if destination != old_bucket:
            links[current] = head[new_bucket]
            head[new_bucket] = current
        else:
            links[current] = head[old_bucket]
            head[old_bucket] = current
        current = following


def expected_result(values: Sequence[int] | None, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    """Return operation-success bits, oldest operation in the most-significant used bit."""
    operations = _decode(values, input_length, input_is_null)
    if operations is None:
        return -1

    heads = [-1] * MAX_BUCKETS
    keys = [0] * MAX_OPERATIONS
    links = [-1] * MAX_OPERATIONS
    level = 1
    split = 0
    live_count = 0
    allocated = 0
    result = 0

    for opcode, key in operations:
        bucket = _bucket(key, level, split)
        previous = -1
        node = heads[bucket]
        while node != -1 and keys[node] != key:
            previous = node
            node = links[node]
        found = node != -1
        succeeded = 0

        if opcode == 0 and not found:
            node = allocated
            allocated += 1
            keys[node] = key
            links[node] = heads[bucket]
            heads[bucket] = node
            live_count += 1
            succeeded = 1
            bucket_count = (1 << level) + split
            if bucket_count < MAX_BUCKETS and live_count > 2 * bucket_count:
                _split(heads, keys, links, level, split)
                split += 1
                if split == 1 << level:
                    level += 1
                    split = 0
        elif opcode == 1 and found:
            if previous == -1:
                heads[bucket] = links[node]
            else:
                links[previous] = links[node]
            live_count -= 1
            succeeded = 1
        elif opcode == 2 and found:
            succeeded = 1

        result = (result << 1) | succeeded
    return result
