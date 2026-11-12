"""Open-addressed hash join for two small relations of signed integer keys."""

from __future__ import annotations

from collections.abc import Sequence

MAX_ROWS_PER_SIDE = 8
HASH_CAPACITY = 17
MAX_VALID_INPUT_LENGTH = 2 + 2 * MAX_ROWS_PER_SIDE
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_OUTPUT_BYTES = MAX_ROWS_PER_SIDE * MAX_ROWS_PER_SIDE
WORKSPACE_BYTES = 1024
MAX_WORKSPACE_BYTES = WORKSPACE_BYTES


def _parse(
    values: Sequence[int] | None,
    input_is_null: bool,
    input_length: int | None,
) -> tuple[tuple[int, ...], tuple[int, ...]] | None:
    if input_is_null or not isinstance(values, (list, tuple)):
        return None
    if not 2 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH:
        return None
    if input_length is not None and (type(input_length) is not int or input_length != len(values)):
        return None
    if any(type(value) is not int or not -(1 << 63) <= value < (1 << 63) for value in values):
        return None
    left_count, right_count = values[:2]
    if not 0 <= left_count <= MAX_ROWS_PER_SIDE or not 0 <= right_count <= MAX_ROWS_PER_SIDE:
        return None
    if len(values) != 2 + left_count + right_count:
        return None
    split = 2 + left_count
    return tuple(values[2:split]), tuple(values[split:])


def _bucket(key: int) -> int:
    return key % HASH_CAPACITY


def _hash_join(left: Sequence[int], right: Sequence[int]) -> bytes:
    build_left = len(left) < len(right)
    build = left if build_left else right
    probe = right if build_left else left

    keys: list[int | None] = [None] * HASH_CAPACITY
    heads = [-1] * HASH_CAPACITY
    tails = [-1] * HASH_CAPACITY
    next_row = [-1] * len(build)

    for row_id, key in enumerate(build):
        slot = _bucket(key)
        while keys[slot] is not None and keys[slot] != key:
            slot = (slot + 1) % HASH_CAPACITY
        if keys[slot] is None:
            keys[slot] = key
        if tails[slot] < 0:
            heads[slot] = row_id
        else:
            next_row[tails[slot]] = row_id
        tails[slot] = row_id

    result = bytearray()
    for probe_id, key in enumerate(probe):
        slot = _bucket(key)
        while keys[slot] is not None and keys[slot] != key:
            slot = (slot + 1) % HASH_CAPACITY
        if keys[slot] is None:
            continue
        build_id = heads[slot]
        while build_id >= 0:
            left_id = build_id if build_left else probe_id
            right_id = probe_id if build_left else build_id
            result.append((left_id << 4) | right_id)
            build_id = next_row[build_id]
    return bytes(result)


def expected_output(
    values: Sequence[int] | None,
    capacity: int | None = None,
    output_is_null: bool = False,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> tuple[int, bytes]:
    parsed = _parse(values, input_is_null, input_length)
    if parsed is None:
        return -1, b""
    if type(output_is_null) is not bool:
        return -1, b""
    if capacity is not None and (type(capacity) is not int or capacity < 0):
        return -1, b""
    output = _hash_join(*parsed)
    if output_is_null or capacity is not None and capacity < len(output):
        return -2, b""
    return len(output), output
