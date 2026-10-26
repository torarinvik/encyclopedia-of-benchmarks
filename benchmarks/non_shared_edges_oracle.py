"""Clean-room Robinson–Foulds non-shared edge distance oracle."""

from __future__ import annotations

import struct
from collections.abc import Sequence

MAX_LEAVES = 8
MAX_INPUT = 27


def _valid_phylogeny(splits: Sequence[int], leaves: int) -> bool:
    edge_count = 2 * leaves - 3
    universe = (1 << leaves) - 1
    if len(splits) != edge_count or any(type(split) is not int for split in splits):
        return False
    if any(split <= 0 or split >= universe or split & 1 for split in splits):
        return False
    if len(set(splits)) != edge_count:
        return False
    required_pendants = {(1 << leaf) for leaf in range(1, leaves)} | {universe ^ 1}
    if not required_pendants.issubset(splits):
        return False
    internals = [split for split in splits if 2 <= split.bit_count() <= leaves - 2]
    if len(internals) != leaves - 3:
        return False
    for index, left in enumerate(internals):
        for right in internals[index + 1:]:
            intersection = left & right
            if intersection and intersection != left and intersection != right:
                return False
    return True


def _parse(values: Sequence[int] | None) -> tuple[list[int], list[int], int] | None:
    if not isinstance(values, (tuple, list)) or not 7 <= len(values) <= MAX_INPUT:
        return None
    if any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
           for value in values):
        return None
    leaves = values[0]
    if not 3 <= leaves <= MAX_LEAVES:
        return None
    edge_count = 2 * leaves - 3
    if len(values) != 1 + 2 * edge_count:
        return None
    first = list(values[1:1 + edge_count])
    second = list(values[1 + edge_count:])
    if not _valid_phylogeny(first, leaves) or not _valid_phylogeny(second, leaves):
        return None
    return first, second, edge_count


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or capacity is not None and (type(capacity) is not int or capacity < 0)
            or input_length is not None and (type(input_length) is not int
                                             or not 0 <= input_length <= MAX_INPUT)
            or input_is_null and values not in (None, [], ())
            or not input_is_null and values is not None and input_length is not None
            and input_length != len(values)):
        return -1, b""
    if input_is_null or values is None:
        return -1, b""
    parsed = _parse(values)
    if parsed is None:
        return -1, b""
    first, second, edge_count = parsed
    shared = len(set(first).intersection(second))
    payload = struct.pack("<q", edge_count - shared)
    if output_is_null or capacity is not None and capacity < len(payload):
        return -2, b""
    return len(payload), payload
