"""Backtracking set-cover verifier for exact two-level Boolean minimization."""

from __future__ import annotations

import struct
from collections.abc import Sequence

MAX_VARIABLES = 3
MAX_INPUT = 1 + (1 << MAX_VARIABLES)


def _all_legal_cubes(statuses: Sequence[int], n: int) -> list[tuple[int, int, int, int]]:
    size = 1 << n
    full = size - 1
    cubes: list[tuple[int, int, int, int]] = []
    for care in range(full + 1):
        for value in range(full + 1):
            if value & ~care:
                continue
            cover = 0
            valid = True
            for minterm in range(size):
                if minterm & care == value:
                    if statuses[minterm] == 0:
                        valid = False
                        break
                    if statuses[minterm] == 1:
                        cover |= 1 << minterm
            if valid and cover:
                cubes.append((care, value, cover, care.bit_count()))
    return cubes


def _search(statuses: Sequence[int], n: int) -> list[tuple[int, int]]:
    required = sum(1 << index for index, status in enumerate(statuses) if status == 1)
    if required == 0:
        return []
    cubes = _all_legal_cubes(statuses, n)
    best_cost: tuple[int, int, tuple[tuple[int, int], ...]] | None = None
    best: tuple[tuple[int, int], ...] = ()

    def visit(covered: int, chosen: list[tuple[int, int]], literals: int) -> None:
        nonlocal best_cost, best
        if covered == required:
            ordered = tuple(sorted(chosen))
            cost = (len(ordered), literals, ordered)
            if best_cost is None or cost < best_cost:
                best_cost = cost
                best = ordered
            return
        if best_cost is not None and len(chosen) >= best_cost[0]:
            return
        uncovered = required & ~covered
        target = (uncovered & -uncovered).bit_length() - 1
        for care, value, cube_cover, literal_count in cubes:
            if not cube_cover & (1 << target):
                continue
            if any(old_care == care and old_value == value for old_care, old_value in chosen):
                continue
            chosen.append((care, value))
            visit(covered | cube_cover, chosen, literals + literal_count)
            chosen.pop()

    visit(0, [], 0)
    return list(best)


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or capacity is not None and (type(capacity) is not int or capacity < 0)
            or input_length is not None and (type(input_length) is not int or not 0 <= input_length <= MAX_INPUT)):
        return -1, b""
    if input_is_null or values is None or not isinstance(values, (list, tuple)):
        if input_is_null and values not in (None, [], ()):
            return -1, b""
        return -1, b""
    if input_length is not None and input_length != len(values):
        return -1, b""
    if not 2 <= len(values) <= MAX_INPUT or any(type(value) is not int or not -(1 << 63) <= value <= (1 << 63) - 1 for value in values):
        return -1, b""
    n = values[0]
    if not 1 <= n <= MAX_VARIABLES or len(values) != 1 + (1 << n):
        return -1, b""
    statuses = list(values[1:])
    if any(status not in (0, 1, 2) for status in statuses):
        return -1, b""
    implicants = _search(statuses, n)
    words = [len(implicants)]
    for care, value in implicants:
        words.extend((care, value))
    payload = struct.pack("<" + "q" * len(words), *words)
    if output_is_null or capacity is not None and capacity < len(payload):
        return -2, b""
    return len(payload), payload
