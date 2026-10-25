"""Independent model of the bounded VersaBench insertEntry success path."""
from __future__ import annotations

from collections.abc import Sequence
import struct

MAX_DEPTH = 2
MAX_CHILDREN = 4
MAX_LEAF = 3
MAX_INPUT_LENGTH = 104
MAX_PARSEABLE_INPUT_LENGTH = 105
MAX_OUTPUT_ELEMENTS = 28
MAX_OUTPUT_BYTES = MAX_OUTPUT_ELEMENTS * 8


def _valid_box(box: Sequence[int]) -> bool:
    return len(box) == 8 and all(-8 <= box[d] < box[4+d] <= 8 for d in range(4))


def _union(boxes: Sequence[Sequence[int]]) -> tuple[int, ...]:
    return tuple(min(b[d] for b in boxes) for d in range(4)) + tuple(
        max(b[4+d] for b in boxes) for d in range(4)
    )


def _volume(box: Sequence[int]) -> int:
    out = 1
    for d in range(4):
        out *= box[4+d] - box[d]
    return out


def expected_output(values: Sequence[int] | None,
                    output_capacity: int | None = MAX_OUTPUT_BYTES,
                    output_is_null: bool = False,
                    input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if (type(input_is_null) is not bool or input_is_null or values is None
            or not isinstance(values, (list, tuple))
            or not 1 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
            or (input_length is not None and
                (type(input_length) is not int or input_length != len(values)))
            or any(type(x) is not int or not -(1 << 63) <= x < (1 << 63) for x in values)):
        return -1, b""
    if len(values) < 11:
        return -1, b""
    depth, new_id = values[:2]
    incoming = tuple(values[2:10])
    if not 0 <= depth <= MAX_DEPTH or not 0 <= new_id < 32 or not _valid_box(incoming):
        return -1, b""

    cursor = 10
    levels: list[list[tuple[int, ...]]] = []
    for _ in range(depth):
        if cursor >= len(values):
            return -1, b""
        count = values[cursor]
        cursor += 1
        if not 1 <= count <= MAX_CHILDREN or cursor + count * 8 > len(values):
            return -1, b""
        boxes = [tuple(values[cursor + i*8:cursor + (i+1)*8]) for i in range(count)]
        cursor += count * 8
        if any(not _valid_box(box) for box in boxes):
            return -1, b""
        levels.append(boxes)

    if cursor >= len(values):
        return -1, b""
    leaf_count = values[cursor]
    cursor += 1
    if (not 0 <= leaf_count <= MAX_LEAF or (depth > 0 and leaf_count == 0)
            or cursor + leaf_count * 9 > len(values)):
        return -1, b""
    leaves: list[tuple[tuple[int, ...], int]] = []
    ids: set[int] = set()
    for _ in range(leaf_count):
        box = tuple(values[cursor:cursor+8])
        record_id = values[cursor+8]
        cursor += 9
        if (not _valid_box(box) or not 0 <= record_id < 32 or record_id in ids):
            return -1, b""
        ids.add(record_id)
        leaves.append((box, record_id))
    if cursor != len(values) or new_id in ids:
        return -1, b""

    # chooseEntry is called with the inserted key at each level. Strict < preserves the first tie.
    choices: list[int] = []
    for boxes in levels:
        penalties = []
        for box in boxes:
            joined = _union((box, incoming))
            penalties.append(_volume(joined) - _volume(box))
        choices.append(min(range(len(boxes)), key=lambda i: penalties[i]))

    if depth:
        child_before = _union([box for box, _ in leaves])
        for level in range(depth - 1, -1, -1):
            if levels[level][choices[level]] != child_before:
                return -1, b""
            child_before = _union(levels[level])

    leaf_after = _union([box for box, _ in leaves] + [incoming])
    words = [depth, new_id, *choices, *leaf_after]
    child_after = leaf_after
    for level in range(depth - 1, -1, -1):
        changed = list(levels[level])
        changed[choices[level]] = child_after
        child_after = _union(changed)
        words.extend(child_after)
    output = b"".join(struct.pack("<q", word) for word in words)
    if type(output_is_null) is not bool or type(output_capacity) is not int or output_capacity < 0:
        return -1, b""
    if output_is_null or output_capacity < len(output):
        return -2, b""
    return len(output), output


oracle = expected_output
