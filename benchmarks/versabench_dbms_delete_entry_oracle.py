"""Independent model for bounded VersaBench deleteEntry traversal/removal."""
from __future__ import annotations

from collections.abc import Sequence
import struct

MAX_CHILDREN = 4
MAX_RECORDS_PER_LEAF = 4
MAX_INPUT_LENGTH = 189
MAX_PARSEABLE_INPUT_LENGTH = 190
MAX_OUTPUT_ELEMENTS = 181
MAX_OUTPUT_BYTES = MAX_OUTPUT_ELEMENTS * 8


def _valid_box(box: Sequence[int]) -> bool:
    return len(box) == 8 and all(-8 <= box[d] < box[4+d] <= 8 for d in range(4))


def _union(boxes: Sequence[Sequence[int]]) -> tuple[int, ...]:
    return tuple(min(box[d] for box in boxes) for d in range(4)) + tuple(
        max(box[4+d] for box in boxes) for d in range(4)
    )


def _intersects(box: Sequence[int], query: Sequence[int]) -> bool:
    return all(not (query[d] > box[4+d] or box[d] > query[4+d]) for d in range(4))


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
    if len(values) < 10:
        return -1, b""
    child_count = values[0]
    query = tuple(values[1:9])
    if not 1 <= child_count <= MAX_CHILDREN or not _valid_box(query):
        return -1, b""

    cursor = 9
    children: list[tuple[tuple[int, ...], list[tuple[tuple[int, ...], int]]]] = []
    ids: set[int] = set()
    for _ in range(child_count):
        if cursor + 9 > len(values):
            return -1, b""
        count = values[cursor]
        cursor += 1
        mbr = tuple(values[cursor:cursor+8])
        cursor += 8
        if not 1 <= count <= MAX_RECORDS_PER_LEAF or not _valid_box(mbr) or cursor + count * 9 > len(values):
            return -1, b""
        records = []
        for _record in range(count):
            box = tuple(values[cursor:cursor+8])
            record_id = values[cursor+8]
            cursor += 9
            if not _valid_box(box) or not 0 <= record_id < 32 or record_id in ids:
                return -1, b""
            ids.add(record_id)
            records.append((box, record_id))
        if _union([box for box, _ in records]) != mbr:
            return -1, b""
        children.append((mbr, records))
    if cursor != len(values):
        return -1, b""

    survivors = []
    for _mbr, records in children:
        # deleteEntry prunes an internal branch by key and checks matching leaves.
        kept = [(box, record_id) for box, record_id in records
                if not _intersects(box, query)]
        if kept:
            survivors.append((_union([box for box, _ in kept]), kept))

    words = [len(survivors)]
    for mbr, records in survivors:
        words.extend([len(records), *mbr])
        for box, record_id in records:
            words.extend([*box, record_id])
    output = b"".join(struct.pack("<q", word) for word in words)
    if type(output_is_null) is not bool or type(output_capacity) is not int or output_capacity < 0:
        return -1, b""
    if output_is_null or output_capacity < len(output):
        return -2, b""
    return len(output), output


oracle = expected_output
