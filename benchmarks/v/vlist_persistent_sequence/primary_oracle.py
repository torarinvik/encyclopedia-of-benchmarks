"""Block-and-offset model of Bagwell's geometric VList."""

from __future__ import annotations

import struct

MAX_Q = 48
MAX_CONS = 32
MAX_VALUE = 1_000_000
MIN_VALUE = -1_000_000
MAX_VALID_INPUT = 145
MAX_PARSEABLE_INPUT = 146
MAX_OUTPUT_BYTES = 384
MAX_WORKSPACE_BYTES = 4096
INVALID_RESULT = -1
OUTPUT_ERROR = -2


def _decode(values, input_length=None, input_is_null=False):
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple))
            or not 1 <= len(values) <= MAX_PARSEABLE_INPUT
            or any(type(v) is not int or not -(1 << 63) <= v < (1 << 63) for v in values)
            or input_length is not None
            and (type(input_length) is not int or input_length != len(values))):
        return None
    q = values[0]
    if type(q) is not int or not 1 <= q <= MAX_Q or len(values) != 1 + 3 * q:
        return None
    return q


def _length(roots, blocks, root_id):
    block_id, offset = roots[root_id]
    total = 0
    while block_id >= 0:
        block = blocks[block_id]
        if not 0 <= offset <= block["last_used"]:
            return None
        total += offset + 1
        block_id, offset = block["prev"], block["prev_offset"]
    return total


def _nth(roots, blocks, storage, root_id, index):
    block_id, offset = roots[root_id]
    remaining = index
    while block_id >= 0:
        if not 0 <= offset <= blocks[block_id]["last_used"]:
            return None
        if remaining <= offset:
            block = blocks[block_id]
            return storage[block["base"] + offset - remaining]
        remaining -= offset + 1
        block_id, offset = blocks[block_id]["prev"], blocks[block_id]["prev_offset"]
    return None


def _simulate(values, input_length=None, input_is_null=False):
    q = _decode(values, input_length, input_is_null)
    if q is None:
        return None
    blocks = []
    storage = [0] * 63
    slot_cursor = 0
    roots = [(-1, -1)]
    outputs = []
    cons_count = 0
    query_phase = False
    at = 1
    for _ in range(q):
        tag, root_id, argument = values[at:at + 3]
        at += 3
        if not 0 <= root_id < len(roots):
            return None
        if tag == 0:
            if (query_phase or root_id != len(roots) - 1 or cons_count >= MAX_CONS
                    or not MIN_VALUE <= argument <= MAX_VALUE):
                return None
            block_id, offset = roots[root_id]
            if block_id < 0:
                if cons_count != 0:
                    return None
                capacity = 1
                base = slot_cursor
                if base + capacity > len(storage):
                    return None
                blocks.append({"prev": -1, "prev_offset": -1, "capacity": capacity,
                               "last_used": 0, "base": base})
                block_id, offset = len(blocks) - 1, 0
                storage[base] = argument
                slot_cursor += capacity
            else:
                block = blocks[block_id]
                if offset != block["last_used"]:
                    return None
                if offset + 1 < block["capacity"]:
                    offset += 1
                    storage[block["base"] + offset] = argument
                    block["last_used"] = offset
                else:
                    capacity = block["capacity"] * 2
                    base = slot_cursor
                    if len(blocks) >= 6 or base + capacity > len(storage):
                        return None
                    blocks.append({"prev": block_id, "prev_offset": offset,
                                   "capacity": capacity, "last_used": 0,
                                   "base": base})
                    block_id, offset = len(blocks) - 1, 0
                    storage[base] = argument
                    slot_cursor += capacity
            roots.append((block_id, offset))
            outputs.append(len(roots) - 1)
            cons_count += 1
            continue

        query_phase = True
        if tag == 1:
            if argument != -1 or _length(roots, blocks, root_id) in (None, 0):
                return None
            block_id, offset = roots[root_id]
            if offset > 0:
                tail = (block_id, offset - 1)
            else:
                block = blocks[block_id]
                tail = (block["prev"], block["prev_offset"])
            roots.append(tail)
            outputs.append(len(roots) - 1)
        elif tag == 2:
            length = _length(roots, blocks, root_id)
            if type(argument) is not int or length is None or not 0 <= argument < length:
                return None
            value = _nth(roots, blocks, storage, root_id, argument)
            if value is None:
                return None
            outputs.append(value)
        elif tag == 3:
            if argument != -1:
                return None
            length = _length(roots, blocks, root_id)
            if length is None:
                return None
            outputs.append(length)
        else:
            return None
        if len(roots) > MAX_Q + 1:
            return None
    return outputs


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
