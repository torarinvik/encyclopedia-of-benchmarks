"""Exact-rational oracle for the DOI 806 submodular-ranking greedy rule."""

from __future__ import annotations

import struct
from collections.abc import Sequence
from fractions import Fraction

MAX_N = 5
MAX_M = 4
MAX_SUBSETS = 1 << MAX_N
MAX_VALID_INPUT_LENGTH = 2 + MAX_M * MAX_SUBSETS
MAX_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_OUTPUT_BYTES = 8 * (1 + MAX_N + MAX_M)


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or capacity is not None and (type(capacity) is not int or capacity < 0)
            or input_length is not None and (type(input_length) is not int or input_length < 0)
            or input_is_null and values not in (None, [], ())
            or not input_is_null and values is not None and input_length is not None
            and input_length != len(values)):
        return -1, b""
    if input_is_null or values is None or not isinstance(values, (list, tuple)):
        return -1, b""
    if not 2 <= len(values) <= MAX_INPUT_LENGTH or any(
            type(v) is not int or not -(1 << 63) <= v < (1 << 63) for v in values):
        return -1, b""
    n, m = values[:2]
    if not 1 <= n <= MAX_N or not 1 <= m <= MAX_M:
        return -1, b""
    size = 1 << n
    if len(values) != 2 + m * size:
        return -1, b""
    tables = [list(values[2 + i * size:2 + (i + 1) * size]) for i in range(m)]
    for table in tables:
        if table[0] != 0 or table[-1] != 8 or any(not 0 <= x <= 8 for x in table):
            return -1, b""
        for mask in range(size):
            for bit in range(n):
                if not (mask >> bit) & 1 and table[mask] > table[mask | (1 << bit)]:
                    return -1, b""
        for a in range(size):
            for b in range(size):
                if a & b != a:
                    continue
                for bit in range(n):
                    if (b >> bit) & 1:
                        continue
                    if table[a | (1 << bit)] - table[a] < table[b | (1 << bit)] - table[b]:
                        return -1, b""

    chosen_order: list[int] = []
    cover_times = [0] * m
    mask = 0
    total = 0
    for time in range(1, n + 1):
        best_element = -1
        best_score = Fraction(-1)
        for element in range(n):
            if mask & (1 << element):
                continue
            score = Fraction(0)
            for i, table in enumerate(tables):
                current = table[mask]
                if current == 8:
                    continue
                gain = table[mask | (1 << element)] - current
                score += Fraction(gain, 8 - current)
            if score > best_score:
                best_score, best_element = score, element
        mask |= 1 << best_element
        chosen_order.append(best_element)
        for i, table in enumerate(tables):
            if cover_times[i] == 0 and table[mask] == 8:
                cover_times[i] = time
                total += time
    packed = (total, *chosen_order, *cover_times)
    output = b"".join(struct.pack("<q", x) for x in packed)
    if output_is_null or capacity is not None and capacity < len(output):
        return -2, b""
    return len(output), output
