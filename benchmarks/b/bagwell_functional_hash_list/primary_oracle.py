"""Block-local hash-chain model of Bagwell's functional hash-list."""

from __future__ import annotations

import struct

MAX_N = 32
MIN_Q = 1
MAX_Q = 32
MAX_VALID_INPUT_LENGTH = 2 + 2 * MAX_N + 2 * MAX_Q
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_OUTPUT_BYTES = 8 * MAX_Q
WORKSPACE_BYTES = 4096
INVALID_RESULT = -1
OUTPUT_ERROR = -2
ABSENT = -(1 << 63)

BLOCK_SIDES = (8, 16, 32)
BLOCK_STARTS = (0, 8, 24)
ENTRY_STARTS = (0, 8, 24)
BUCKET_STARTS = (0, 8, 24)
ENTRY_SLOTS = 56
BUCKET_SLOTS = 56


def _parse(values, input_length=None, input_is_null=False):
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple))
            or not 2 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)
            or input_length is not None
            and (type(input_length) is not int or input_length != len(values))):
        return None
    n = values[0]
    if type(n) is not int or not 0 <= n <= MAX_N:
        return None
    q_at = 1 + 2 * n
    if q_at >= len(values):
        return None
    q = values[q_at]
    if type(q) is not int or not MIN_Q <= q <= MAX_Q:
        return None
    if len(values) != 2 + 2 * n + 2 * q:
        return None
    for index in range(n):
        key = values[1 + 2 * index]
        value = values[2 + 2 * index]
        if not -(1 << 31) <= key < (1 << 31) or not -(1 << 31) <= value < (1 << 31):
            return None
    query_at = q_at + 1
    for index in range(q):
        root = values[query_at + 2 * index]
        key = values[query_at + 2 * index + 1]
        if not 0 <= root <= n or not -(1 << 31) <= key < (1 << 31):
            return None
    return n, q, 1, query_at


def _lookup(keys, values, next_offsets, bucket_heads, block_prev,
            start_block, offset_limit, key):
    if start_block < 0:
        return ABSENT
    hash_value = key & 0xFFFFFFFF
    block = start_block
    first_block = True
    while block >= 0:
        side = BLOCK_SIDES[block]
        bucket = hash_value & (side - 1)
        chain = bucket_heads[BUCKET_STARTS[block] + bucket]
        while chain >= 0:
            if not first_block or chain <= offset_limit:
                entry = ENTRY_STARTS[block] + chain
                if keys[entry] == key:
                    return values[entry]
            chain = next_offsets[ENTRY_STARTS[block] + chain]
        # Fig. 6 lookup falls through the explicit Previous-block link after
        # exhausting the selected block's visible bucket-chain prefix.
        block = block_prev[block]
        first_block = False
    return ABSENT


def _simulate(data, input_length=None, input_is_null=False):
    parsed = _parse(data, input_length, input_is_null)
    if parsed is None:
        return None
    n, q, pairs_at, queries_at = parsed
    keys = [0] * ENTRY_SLOTS
    stored_values = [0] * ENTRY_SLOTS
    next_offsets = [-1] * ENTRY_SLOTS
    bucket_heads = [-1] * BUCKET_SLOTS
    block_prev = [-1] * len(BLOCK_SIDES)
    root_blocks = [-1] * (MAX_N + 1)
    root_offsets = [-1] * (MAX_N + 1)
    current_block = 0

    for entry_index in range(n):
        if entry_index == BLOCK_STARTS[1] or entry_index == BLOCK_STARTS[2]:
            new_block = current_block + 1
            block_prev[new_block] = current_block
            current_block = new_block
        block = current_block
        side = BLOCK_SIDES[block]
        offset = entry_index - BLOCK_STARTS[block]
        key = data[pairs_at + 2 * entry_index]
        value = data[pairs_at + 2 * entry_index + 1]
        hash_value = key & 0xFFFFFFFF
        bucket = hash_value & (side - 1)
        bucket_slot = BUCKET_STARTS[block] + bucket
        entry_slot = ENTRY_STARTS[block] + offset
        keys[entry_slot] = key
        stored_values[entry_slot] = value
        next_offsets[entry_slot] = bucket_heads[bucket_slot]
        bucket_heads[bucket_slot] = offset
        root_blocks[entry_index + 1] = current_block
        root_offsets[entry_index + 1] = offset

    output = []
    for query in range(q):
        root = data[queries_at + 2 * query]
        key = data[queries_at + 2 * query + 1]
        output.append(_lookup(keys, stored_values, next_offsets, bucket_heads, block_prev,
                              root_blocks[root], root_offsets[root], key))
    return output


def expected_output(values, output_capacity=None, output_is_null=False,
                    input_is_null=False, input_length=None):
    words = _simulate(values, input_length, input_is_null)
    if words is None:
        return INVALID_RESULT, b""
    payload = b"".join(struct.pack("<q", word) for word in words)
    if (type(output_is_null) is not bool or output_is_null
            or output_capacity is not None
            and (type(output_capacity) is not int or output_capacity < len(payload))):
        return OUTPUT_ERROR, b""
    return len(payload), payload
