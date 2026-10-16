"""Independent reference for the pinned bounded HyperLogLog behavior."""

from __future__ import annotations

import math
from collections.abc import Sequence

MAX_COUNT = 1024
MAX_VALUE = 65_535
MAX_INPUT_LENGTH = MAX_COUNT + 1
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1


def expected_result(values: Sequence[int]) -> int:
    """Return the source's touched-register-only cardinality estimate."""
    if (not isinstance(values, (list, tuple)) or len(values) < 2
            or len(values) > MAX_INPUT_LENGTH
            or any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values)):
        return -1
    count = values[0]
    if not 1 <= count <= MAX_COUNT or len(values) != count + 1:
        return -1
    items = values[1:]
    if any(not 1 <= value <= MAX_VALUE for value in items):
        return -1

    registers: dict[int, int] = {}
    for value in items:
        rank = (value & -value).bit_length() - 1
        registers[value] = max(registers.get(value, 0), rank)

    k = len(registers)
    z = math.fsum(math.ldexp(1.0, -rank) for rank in registers.values())
    return math.ceil(0.673 * k * (k / z))
