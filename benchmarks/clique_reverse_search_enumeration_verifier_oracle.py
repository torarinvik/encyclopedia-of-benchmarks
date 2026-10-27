"""Subset-parent verifier for the DOI 731 clique reverse-search profile."""

from __future__ import annotations

import struct
from collections.abc import Sequence

MAX_N = 8
MAX_INPUT = 9
MAX_OUTPUT_BYTES = 264


def _parse(values: Sequence[int] | None) -> tuple[int, list[int]] | None:
    if not isinstance(values, (tuple, list)) or not 2 <= len(values) <= MAX_INPUT:
        return None
    if any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
           for value in values):
        return None
    n = values[0]
    if type(n) is not int or not 1 <= n <= MAX_N or len(values) != n + 1:
        return None
    limit = 1 << n
    adjacency = list(values[1:])
    if any(mask < 0 or mask >= limit or mask & (1 << vertex)
           for vertex, mask in enumerate(adjacency)):
        return None
    for left in range(n):
        for right in range(left + 1, n):
            if bool(adjacency[left] & (1 << right)) != bool(adjacency[right] & (1 << left)):
                return None
    return n, adjacency


def _is_clique(mask: int, adjacency: Sequence[int]) -> bool:
    remaining = mask
    while remaining:
        bit = remaining & -remaining
        vertex = bit.bit_length() - 1
        if adjacency[vertex] & mask != mask ^ bit:
            return False
        remaining ^= bit
    return True


def _parent(mask: int) -> int | None:
    return None if mask == 0 else mask & (mask - 1)


def _enumerate(parent: int, candidates: Sequence[int], masks: list[int]) -> None:
    masks.append(parent)
    children = [mask for mask in candidates if mask != 0 and _parent(mask) == parent]
    children.sort(key=lambda mask: (mask & -mask).bit_length())
    for child in children:
        _enumerate(child, candidates, masks)


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
    n, adjacency = parsed
    candidates = [mask for mask in range(1 << n) if _is_clique(mask, adjacency)]
    masks: list[int] = []
    _enumerate(0, candidates, masks)
    payload = struct.pack("<q", len(masks)) + bytes(masks)
    if output_is_null or capacity is not None and capacity < len(payload):
        return -2, b""
    return len(payload), payload
