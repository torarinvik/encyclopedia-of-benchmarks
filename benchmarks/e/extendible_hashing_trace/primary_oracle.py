"""Directory-and-slot model for a bounded extendible-hashing trace."""

from __future__ import annotations

from collections.abc import Sequence

MAX_OPERATIONS = 40
MAX_VALID_INPUT_LENGTH = 1 + 2 * MAX_OPERATIONS
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_DEPTH = 8
BUCKET_CAPACITY = 2
WORKSPACE_BYTES = 8192
INVALID_RESULT = -1


def _parse(values: Sequence[int] | None, input_is_null: bool,
           input_length: int | None) -> list[tuple[int, int]] | None:
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple))
            or not 1 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
            or any(type(x) is not int or not -(1 << 63) <= x < (1 << 63)
                   for x in values)):
        return None
    actual = len(values) if input_length is None else input_length
    if type(actual) is not int or actual != len(values):
        return None
    q = values[0]
    if not 0 <= q <= MAX_OPERATIONS or len(values) != 1 + 2 * q:
        return None
    operations: list[tuple[int, int]] = []
    for i in range(q):
        opcode, key = values[1 + 2 * i:3 + 2 * i]
        if opcode not in (0, 1, 2) or not 0 <= key <= 255:
            return None
        operations.append((opcode, key))
    return operations


def _directory_run(operations: list[tuple[int, int]]) -> int:
    directory = [0] * 256
    keys = [[0, 0] for _ in range(256)]
    counts = [0] * 256
    depths = [0] * 256
    active = [False] * 256
    active[0] = active[1] = True
    depths[0] = depths[1] = 1
    directory[0], directory[1] = 0, 1
    global_depth = max_depth = 1
    live = buckets = 2
    successes = 0

    def bucket_for(key: int) -> int:
        return directory[key & ((1 << global_depth) - 1)]

    def find_slot(bucket: int, key: int) -> int:
        for slot in range(counts[bucket]):
            if keys[bucket][slot] == key:
                return slot
        return -1

    def split(bucket: int) -> bool:
        nonlocal global_depth, max_depth, buckets
        depth = depths[bucket]
        if depth >= MAX_DEPTH:
            return False
        if global_depth == depth:
            old_size = 1 << global_depth
            for index in range(old_size):
                directory[index + old_size] = directory[index]
            global_depth += 1
            max_depth = max(max_depth, global_depth)
        fresh = next((i for i in range(256) if not active[i]), -1)
        if fresh < 0:
            return False
        active[fresh] = True
        depths[bucket] = depth + 1
        depths[fresh] = depth + 1
        old_keys = keys[bucket][:counts[bucket]]
        keys[bucket] = [0, 0]
        keys[fresh] = [0, 0]
        counts[bucket] = counts[fresh] = 0
        bit = 1 << depth
        size = 1 << global_depth
        for index in range(size):
            if directory[index] == bucket and index & bit:
                directory[index] = fresh
        for value in old_keys:
            target = fresh if value & bit else bucket
            keys[target][counts[target]] = value
            counts[target] += 1
        buckets += 1
        return True

    def coalesce(bucket: int) -> None:
        nonlocal global_depth, buckets
        while depths[bucket] > 1:
            depth = depths[bucket]
            size = 1 << global_depth
            representative = next(i for i in range(size) if directory[i] == bucket)
            prefix_mask = (1 << depth) - 1
            prefix = representative & prefix_mask
            buddy_prefix = prefix ^ (1 << (depth - 1))
            buddy = directory[buddy_prefix]
            if buddy == bucket or not active[buddy] or depths[buddy] != depth:
                break
            if counts[bucket] + counts[buddy] > BUCKET_CAPACITY:
                break
            if buddy_prefix < prefix:
                survivor, removed = buddy, bucket
            else:
                survivor, removed = bucket, buddy
            for slot in range(counts[removed]):
                keys[survivor][counts[survivor] + slot] = keys[removed][slot]
            counts[survivor] += counts[removed]
            counts[removed] = 0
            depths[survivor] = depth - 1
            active[removed] = False
            size = 1 << global_depth
            for index in range(size):
                if directory[index] == removed:
                    directory[index] = survivor
            buckets -= 1
            bucket = survivor
        while global_depth > 1:
            half = 1 << (global_depth - 1)
            if any(directory[i] != directory[i + half] for i in range(half)):
                break
            global_depth -= 1

    for opcode, key in operations:
        success = 0
        bucket = bucket_for(key)
        slot = find_slot(bucket, key)
        if opcode == 0:
            if slot < 0:
                while counts[bucket] == BUCKET_CAPACITY:
                    if not split(bucket):
                        break
                    bucket = bucket_for(key)
                if counts[bucket] < BUCKET_CAPACITY:
                    keys[bucket][counts[bucket]] = key
                    counts[bucket] += 1
                    live += 1
                    success = 1
        elif opcode == 1:
            if slot >= 0:
                counts[bucket] -= 1
                keys[bucket][slot] = keys[bucket][counts[bucket]]
                keys[bucket][counts[bucket]] = 0
                live -= 1
                success = 1
                coalesce(bucket)
        else:
            success = int(slot >= 0)
        successes = (successes << 1) | success
    return (successes | (buckets << 40) | (global_depth << 49)
            | (max_depth << 53) | (live << 57))


def expected_result(values: Sequence[int] | None, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    operations = _parse(values, input_is_null, input_length)
    return INVALID_RESULT if operations is None else _directory_run(operations)
