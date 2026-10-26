"""Fraction-based independent verifier for weighted greedy set cover."""

from __future__ import annotations

import struct
from collections.abc import Sequence
from fractions import Fraction

MAX_N = 16
MAX_M = 16
MAX_INPUT = 2 + 2 * MAX_M
MAX_INPUT_LENGTH = MAX_INPUT
MAX_OUTPUT_BYTES = 8 * (MAX_M + 1)


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or capacity is not None and (type(capacity) is not int or capacity < 0)
            or input_length is not None and
            (type(input_length) is not int or not 0 <= input_length <= MAX_INPUT)
            or input_is_null and values not in (None, [], ())
            or not input_is_null and values is not None and input_length is not None
            and isinstance(values, (list, tuple)) and input_length != len(values)):
        return -1, b""
    if input_is_null or values is None or not isinstance(values, (list, tuple)):
        return -1, b""
    if (len(values) < 4 or len(values) > MAX_INPUT or any(
            type(value) is not int or not -(1 << 63) <= value < (1 << 63)
            for value in values)):
        return -1, b""
    n, m = values[0], values[1]
    if not 1 <= n <= MAX_N or not 1 <= m <= MAX_M or len(values) != 2 + 2 * m:
        return -1, b""
    costs = values[2:2 + m]
    masks = values[2 + m:]
    if any(not 0 <= cost <= 10000 for cost in costs):
        return -1, b""
    full = (1 << n) - 1
    if any(mask < 0 or mask > full for mask in masks):
        return -1, b""
    element_sets = [set(element for element in range(n) if mask & (1 << element))
                    for mask in masks]
    if set.union(*element_sets) != set(range(n)):
        return -1, b""
    covered: set[int] = set()
    selected: list[int] = []
    while len(covered) < n:
        best = -1
        best_ratio: Fraction | None = None
        for index, elements in enumerate(element_sets):
            newly_covered = len(elements - covered)
            if newly_covered == 0:
                continue
            ratio = Fraction(costs[index], newly_covered)
            if best_ratio is None or ratio < best_ratio:
                best = index
                best_ratio = ratio
        if best < 0:
            return -1, b""
        selected.append(best)
        covered.update(element_sets[best])
    if output_is_null or capacity is not None and capacity < 8 * (len(selected) + 1):
        return -2, b""
    output = b"".join(struct.pack("<q", value) for value in (len(selected), *selected))
    return len(output), output
