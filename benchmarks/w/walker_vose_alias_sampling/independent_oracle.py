"""Reference using explicitly filled column slots and mass conservation."""

from __future__ import annotations

import struct
from collections import deque
from collections.abc import Sequence


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if (type(input_is_null) is not bool or type(output_is_null) is not bool
            or input_is_null or not isinstance(values, (list, tuple))
            or not 3 <= len(values) <= 83
            or input_length is not None and (type(input_length) is not int or input_length != len(values))
            or capacity is not None and (type(capacity) is not int or capacity < 0)
            or any(type(x) is not int or x < -(1 << 63) or x >= 1 << 63 for x in values)):
        return -1, b""
    n, q = values[:2]
    if not 1 <= n <= 16 or not 0 <= q <= 32 or len(values) != 2 + n + 2 * q:
        return -1, b""
    weights = values[2:2 + n]
    if any(w < 0 or w > 100 for w in weights) or sum(weights) == 0:
        return -1, b""
    total = sum(weights)
    draws = list(zip(values[2 + n::2], values[3 + n::2]))
    if any(not 0 <= col < n or not 0 <= ticket < total for col, ticket in draws):
        return -1, b""
    if q == 0:
        return 0, b""
    if output_is_null or capacity is not None and capacity < 8 * q:
        return -2, b""
    remaining = [n * w for w in weights]
    small = deque(i for i, mass in enumerate(remaining) if mass < total)
    large = deque(i for i, mass in enumerate(remaining) if mass >= total)
    slots = [[(i, total)] for i in range(n)]
    while small and large:
        low, high = small.pop(), large.pop()
        own = remaining[low]
        slots[low] = [(low, own), (high, total - own)]
        remaining[high] -= total - own
        (small if remaining[high] < total else large).append(high)
    allocated = [0] * n
    for slot in slots:
        for category, count in slot:
            allocated[category] += count
    if allocated != [n * w for w in weights]:
        raise ValueError("alias table does not preserve category weights")
    answers = []
    for column, ticket in draws:
        for category, count in slots[column]:
            if ticket < count:
                answers.append(category)
                break
            ticket -= count
    return 8 * q, struct.pack("<" + "q" * q, *answers)
