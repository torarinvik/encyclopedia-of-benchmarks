"""Prefix-bucket model, independent of the explicit directory simulation."""

from __future__ import annotations

from collections.abc import Sequence

MAX_OPERATIONS = 40
MAX_VALID_INPUT_LENGTH = 1 + 2 * MAX_OPERATIONS
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_DEPTH = 8
WORKSPACE_BYTES = 8192


def _decode(values: Sequence[int] | None, input_is_null: bool,
            input_length: int | None) -> list[tuple[int, int]] | None:
    if type(input_is_null) is not bool or input_is_null:
        return None
    if not isinstance(values, (list, tuple)) or not 1 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH:
        return None
    if any(type(x) is not int or x < -(1 << 63) or x >= 1 << 63 for x in values):
        return None
    if input_length is not None and (type(input_length) is not int or input_length != len(values)):
        return None
    q = values[0]
    if type(q) is not int or q < 0 or q > MAX_OPERATIONS or len(values) != 1 + 2 * q:
        return None
    result = []
    for i in range(q):
        op, key = values[1 + 2 * i:3 + 2 * i]
        if op not in (0, 1, 2) or key < 0 or key > 255:
            return None
        result.append((op, key))
    return result


def _prefix_run(operations: list[tuple[int, int]]) -> int:
    # Each entry is one nonempty bucket keyed by (local depth, low-bit prefix).
    buckets: dict[tuple[int, int], set[int]] = {(1, 0): set(), (1, 1): set()}
    depth = high_water = 1
    live = 0
    success_word = 0

    def locate(key: int) -> tuple[int, int]:
        for local_depth in range(depth, 0, -1):
            prefix = key & ((1 << local_depth) - 1)
            address = (local_depth, prefix)
            if address in buckets:
                return address
        raise AssertionError("prefix partition must cover every key")

    for opcode, key in operations:
        address = locate(key)
        contents = buckets[address]
        success = 0
        if opcode == 0:
            if key not in contents:
                while len(contents) == 2:
                    local_depth, prefix = address
                    if local_depth == depth:
                        depth += 1
                        high_water = max(high_water, depth)
                    del buckets[address]
                    low = set()
                    high = set()
                    split_bit = 1 << local_depth
                    for existing in contents:
                        (high if existing & split_bit else low).add(existing)
                    buckets[(local_depth + 1, prefix)] = low
                    buckets[(local_depth + 1, prefix | split_bit)] = high
                    address = locate(key)
                    contents = buckets[address]
                contents.add(key)
                live += 1
                success = 1
        elif opcode == 1:
            if key in contents:
                contents.remove(key)
                live -= 1
                success = 1
                while address[0] > 1:
                    local_depth, prefix = address
                    buddy_address = (local_depth, prefix ^ (1 << (local_depth - 1)))
                    buddy = buckets.get(buddy_address)
                    if buddy is None or len(contents) + len(buddy) > 2:
                        break
                    parent_prefix = prefix & ((1 << (local_depth - 1)) - 1)
                    merged = contents | buddy
                    del buckets[address]
                    del buckets[buddy_address]
                    address = (local_depth - 1, parent_prefix)
                    buckets[address] = merged
                    contents = merged
                while depth > 1 and not any(local_depth == depth for local_depth, _ in buckets):
                    depth -= 1
        else:
            success = int(key in contents)
        success_word = (success_word << 1) | success
    return (success_word | (len(buckets) << 40) | (depth << 49)
            | (high_water << 53) | (live << 57))


def expected_result(values: Sequence[int] | None, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    operations = _decode(values, input_is_null, input_length)
    return -1 if operations is None else _prefix_run(operations)
