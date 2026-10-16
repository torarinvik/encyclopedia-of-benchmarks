"""Oracle for deterministic two-point crossover of bounded integer genomes."""

from __future__ import annotations
import struct

MAX_COUNT = 64
MIN_GENE = -(1 << 31)
MAX_GENE = (1 << 31) - 1
INVALID_RESULT = -1

def expected_result(values: list[int] | tuple[int, ...]) -> tuple[int, bytes]:
    if (not isinstance(values, (list, tuple)) or len(values) < 3
            or len(values) > 3 + 2 * MAX_COUNT
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63) for value in values)):
        return INVALID_RESULT, b""
    count, first_cut, second_cut = values[:3]
    if (not 2 <= count <= MAX_COUNT or len(values) != 3 + 2 * count
            or not 1 <= first_cut < second_cut <= count):
        return INVALID_RESULT, b""
    genes = values[3:]
    if any(value < MIN_GENE or value > MAX_GENE for value in genes):
        return INVALID_RESULT, b""
    parent_one = genes[:count]
    parent_two = genes[count:]
    child_one = parent_one[:first_cut] + parent_two[first_cut:second_cut] + parent_one[second_cut:]
    child_two = parent_two[:first_cut] + parent_one[first_cut:second_cut] + parent_two[second_cut:]
    output = b"".join(struct.pack("<q", value) for value in child_one + child_two)
    return len(output), output
