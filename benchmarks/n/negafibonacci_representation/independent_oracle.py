"""Exhaustive legal-mask reference, independent of interval selection."""

from __future__ import annotations

from typing import Optional

from n.negafibonacci_representation.primary_oracle import MAX_INDEX, VALUE_LIMIT, WEIGHTS


def _build_table() -> dict[int, bytes]:
    table: dict[int, bytes] = {}
    for packed in range(1 << MAX_INDEX):
        if packed & (packed << 1):
            continue
        value = sum(WEIGHTS[index]
                    for index in range(1, MAX_INDEX + 1)
                    if packed & (1 << (index - 1)))
        if not (-VALUE_LIMIT <= value <= VALUE_LIMIT):
            continue
        highest = MAX_INDEX
        while highest > 1 and not (packed & (1 << (highest - 1))):
            highest -= 1
        code = "".join("1" if packed & (1 << (index - 1)) else "0"
                       for index in range(highest, 0, -1))
        table[value] = code.encode("ascii")
    return table


_REPRESENTATIONS = _build_table()


def expected_call(values: list[int], capacity: Optional[int] = None) -> tuple[int, bytes]:
    if len(values) != 1 or not (-VALUE_LIMIT <= values[0] <= VALUE_LIMIT):
        return -1, b""
    output = _REPRESENTATIONS[values[0]]
    if capacity is not None and capacity < len(output):
        return -2, b""
    return len(output), output

