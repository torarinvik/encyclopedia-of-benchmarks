"""Disjoint sparse table for ordered affine-map range composition."""

from __future__ import annotations

import struct
from collections.abc import Sequence

MODULUS = 1_000_000_007
MAX_N = 32
MAX_Q = 32
MAX_INPUT_LENGTH = 2 + 2 * MAX_N + 2 * MAX_Q
MAX_OUTPUT_BYTES = 16 * MAX_Q
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1
Affine = tuple[int, int]


def _decode(values: Sequence[int] | None, input_length: int | None,
            input_is_null: bool) -> tuple[list[Affine], list[tuple[int, int]]] | None:
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple))
            or not 2 <= len(values) <= MAX_INPUT_LENGTH
            or any(type(value) is not int or not I64_MIN <= value <= I64_MAX
                   for value in values)):
        return None
    if input_length is not None and (
            type(input_length) is not int or input_length != len(values)):
        return None
    n, q = values[0], values[1]
    if not 1 <= n <= MAX_N or not 1 <= q <= MAX_Q:
        return None
    if len(values) != 2 + 2 * n + 2 * q:
        return None
    maps: list[Affine] = []
    cursor = 2
    for _ in range(n):
        a, b = values[cursor], values[cursor + 1]
        if not 0 <= a < MODULUS or not 0 <= b < MODULUS:
            return None
        maps.append((a, b))
        cursor += 2
    queries: list[tuple[int, int]] = []
    for _ in range(q):
        left, right = values[cursor], values[cursor + 1]
        if not 0 <= left <= right < n:
            return None
        queries.append((left, right))
        cursor += 2
    return maps, queries


def _combine(left: Affine, right: Affine) -> Affine:
    """Return the map that applies left first, then right."""
    return (right[0] * left[0] % MODULUS,
            (right[0] * left[1] + right[1]) % MODULUS)


def _build_table(maps: list[Affine]) -> list[list[Affine]]:
    n = len(maps)
    levels = (n - 1).bit_length()
    table: list[list[Affine]] = [[(0, 0) for _ in range(n)] for _ in range(levels)]
    for level in range(levels):
        half = 1 << level
        width = half << 1
        for start in range(0, n, width):
            middle = min(start + half, n)
            end = min(start + width, n)
            if middle > start:
                table[level][middle - 1] = maps[middle - 1]
                for index in range(middle - 2, start - 1, -1):
                    table[level][index] = _combine(maps[index], table[level][index + 1])
            if middle < end:
                table[level][middle] = maps[middle]
                for index in range(middle + 1, end):
                    table[level][index] = _combine(table[level][index - 1], maps[index])
    return table


def _answers(maps: list[Affine], queries: list[tuple[int, int]]) -> list[Affine]:
    table = _build_table(maps)
    answers: list[Affine] = []
    for left, right in queries:
        if left == right:
            answers.append(maps[left])
        else:
            level = (left ^ right).bit_length() - 1
            answers.append(_combine(table[level][left], table[level][right]))
    return answers


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    decoded = _decode(values, input_length, input_is_null)
    if decoded is None:
        return -1, b""
    maps, queries = decoded
    encoded = b"".join(struct.pack("<q", coefficient)
                        for pair in _answers(maps, queries) for coefficient in pair)
    effective_capacity = MAX_OUTPUT_BYTES if capacity is None else capacity
    if (type(output_is_null) is not bool or type(effective_capacity) is not int
            or effective_capacity < 0):
        return -2, b""
    if output_is_null or len(encoded) > effective_capacity:
        return -2, b""
    return len(encoded), encoded
