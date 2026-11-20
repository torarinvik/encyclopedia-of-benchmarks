"""Linked-level block model of Bagwell's bounded two-dimensional VArray."""

from __future__ import annotations

import struct

MAX_N = 321
MAX_Q = 256
MAX_VALID_INPUT = 2 + MAX_N + MAX_Q
MAX_PARSEABLE_INPUT = MAX_VALID_INPUT + 1
MAX_OUTPUT_BYTES = 8 * (MAX_Q + 1)
MAX_WORKSPACE_BYTES = 4096
INVALID_RESULT = -1
OUTPUT_ERROR = -2

# Fig. 7's s=8 level, followed by levels of side 16 and 32.
LEVEL_STARTS = (0, 64, 320)
LEVEL_SIDES = (8, 16, 32)
LEVEL_POINTER_STARTS = (0, 8, 24)
LEVEL_DATA_STARTS = (0, 64, 320)
DATA_SLOTS = 352
POINTER_SLOTS = 56
LEVEL_HEADER_COUNT = 3


def _parse(values, input_length=None, input_is_null=False):
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple))
            or not 2 <= len(values) <= MAX_PARSEABLE_INPUT
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)
            or input_length is not None
            and (type(input_length) is not int or input_length != len(values))):
        return None
    n, q = values[0], values[1]
    if type(n) is not int or not 0 <= n <= MAX_N:
        return None
    if type(q) is not int or not 0 <= q <= MAX_Q:
        return None
    if len(values) != 2 + n + q or (n == 0 and q != 0):
        return None
    values_end = 2 + n
    if any(not 0 <= index < n for index in values[values_end:]):
        return None
    return n, q, values_end


def _locate(level, index):
    """Return (pointer-slot, child-block offset, element offset)."""
    relative = index - LEVEL_STARTS[level]
    side = LEVEL_SIDES[level]
    child = relative // side
    pointer_slot = LEVEL_POINTER_STARTS[level] + child
    child_base = LEVEL_DATA_STARTS[level] + child * side
    return pointer_slot, child_base, relative % side


def _find_level(index, current_header, previous_header):
    """Follow previous-level links until the selected header covers index."""
    level = current_header
    while level >= 0 and index < LEVEL_STARTS[level]:
        level = previous_header[level]
    return level


def _run(values, input_length=None, input_is_null=False):
    parsed = _parse(values, input_length, input_is_null)
    if parsed is None:
        return None
    n, q, values_end = parsed
    data = [0] * DATA_SLOTS
    pointers = [-1] * POINTER_SLOTS
    previous_header = [-1] * LEVEL_HEADER_COUNT
    current_header = 0

    # Each new level header links to the last completed level; values never move.
    for index in range(n):
        if index in (LEVEL_STARTS[1], LEVEL_STARTS[2]):
            next_header = current_header + 1
            previous_header[next_header] = current_header
            current_header = next_header
        pointer_slot, child_base, element_offset = _locate(current_header, index)
        if pointers[pointer_slot] == -1:
            pointers[pointer_slot] = child_base
        if pointers[pointer_slot] != child_base or child_base + element_offset >= DATA_SLOTS:
            return None
        data[pointers[pointer_slot] + element_offset] = values[2 + index]

    output = [q]
    for query in values[values_end:]:
        level = _find_level(query, current_header, previous_header)
        if level < 0:
            return None
        pointer_slot, child_base, element_offset = _locate(level, query)
        base = pointers[pointer_slot]
        if base < 0 or base != child_base:
            return None
        output.append(data[base + element_offset])
    return output


def expected_output(values, output_capacity=None, output_is_null=False,
                    input_is_null=False, input_length=None):
    words = _run(values, input_length, input_is_null)
    if words is None:
        return INVALID_RESULT, b""
    payload = b"".join(struct.pack("<q", word) for word in words)
    if (type(output_is_null) is not bool or output_is_null
            or output_capacity is not None
            and (type(output_capacity) is not int or output_capacity < len(payload))):
        return OUTPUT_ERROR, b""
    return len(payload), payload
