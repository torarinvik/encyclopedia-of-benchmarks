"""Independent exhaustive-structure verifier for the bounded RNA MFE profile."""

from __future__ import annotations

import struct
from collections.abc import Sequence

PAIR_TYPES = {(0, 3): 0, (3, 0): 1, (1, 2): 2, (2, 1): 3, (2, 3): 4, (3, 2): 5}
TABLE_SIZE = 234


def _decode(values: Sequence[int] | None):
    if (not isinstance(values, (tuple, list)) or len(values) < 239 or len(values) > 247
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63) for value in values)):
        return None
    n = values[0]
    if not 4 <= n <= 12 or len(values) != 1 + n + TABLE_SIZE:
        return None
    bases, table = list(values[1:1+n]), list(values[1+n:])
    if any(base not in (0, 1, 2, 3) for base in bases) or any(cost < -1000 or cost > 1000 for cost in table):
        return None
    return n, bases, table


def _structures(lo: int, hi: int, pair_type: list[list[int]]):
    if lo >= hi:
        yield ()
        return
    yield from _structures(lo + 1, hi, pair_type)
    for end in range(lo + 4, hi):
        if pair_type[lo][end] < 0:
            continue
        for inside in _structures(lo + 1, end, pair_type):
            for suffix in _structures(end + 1, hi, pair_type):
                yield ((lo, end),) + inside + suffix


def _energy_of_structure(pairs: tuple[tuple[int, int], ...], pair_type: list[list[int]],
                         table: list[int], n: int) -> int:
    total = 0
    for outer_i, outer_j in pairs:
        direct_children = []
        for child_i, child_j in pairs:
            if not (outer_i < child_i < child_j < outer_j):
                continue
            hidden_by_middle = any(
                outer_i < middle_i < child_i < child_j < middle_j < outer_j
                for middle_i, middle_j in pairs
            )
            if not hidden_by_middle:
                direct_children.append((child_i, child_j))
        direct_children.sort()
        unpaired = 0
        cursor = outer_i + 1
        for child_i, child_j in direct_children:
            unpaired += child_i - cursor
            cursor = child_j + 1
        unpaired += outer_j - cursor
        child_count = len(direct_children)
        if child_count > 2:
            raise ValueError("three direct children cannot fit in the bounded domain")
        kind = pair_type[outer_i][outer_j]
        total += table[kind * 39 + unpaired * 3 + child_count]
    return total


def _solve(n: int, bases: list[int], table: list[int]):
    pair_type = [[-1] * n for _ in range(n)]
    for i in range(n):
        for j in range(i + 4, n):
            pair_type[i][j] = PAIR_TYPES.get((bases[i], bases[j]), -1)
    best_energy = 1 << 60
    best_pairs: tuple[tuple[int, int], ...] = ()
    for candidate in _structures(0, n, pair_type):
        energy = _energy_of_structure(candidate, pair_type, table, n)
        if energy < best_energy or energy == best_energy and candidate < best_pairs:
            best_energy, best_pairs = energy, candidate
    return best_energy, list(best_pairs)


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or capacity is not None and (type(capacity) is not int or capacity < 0)
            or input_length is not None and (type(input_length) is not int or not 0 <= input_length <= 247)
            or input_is_null and values not in (None, [], ())
            or not input_is_null and values is not None and input_length is not None
            and input_length != len(values)):
        return -1, b""
    if input_is_null or values is None:
        return -1, b""
    decoded = _decode(values)
    if decoded is None:
        return -1, b""
    n, bases, table = decoded
    energy, pairs = _solve(n, bases, table)
    fields = [energy, len(pairs)]
    for i, j in pairs:
        fields.extend((i, j))
    payload = b"".join(struct.pack("<q", value) for value in fields)
    if output_is_null or capacity is not None and capacity < len(payload):
        return -2, b""
    return len(payload), payload
