"""Exhaustively enumerate bounded edge flows and check vertex conservation."""

from __future__ import annotations

from collections.abc import Sequence


def _read(values: Sequence[int] | None, input_is_null: bool,
          input_length: int | None):
    # Keep this parser separate from the max-flow reference implementation.
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple))
            or not 2 <= len(values) <= 35
            or any(type(item) is not int or not -(1 << 63) <= item < (1 << 63)
                   for item in values)):
        return None
    if input_length is not None and (
            type(input_length) is not int or input_length != len(values)):
        return None
    n, count = values[0], values[1]
    if not 1 <= n <= 6 or not 0 <= count <= 8 or len(values) != 2 + 4 * count:
        return None
    arcs: list[tuple[int, int, int, int]] = []
    for pos in range(count):
        start = 2 + 4 * pos
        source, target, low, high = values[start:start + 4]
        if (source < 0 or source >= n or target < 0 or target >= n
                or low < 0 or high < low or high > 2):
            return None
        arcs.append((source, target, low, high))
    return n, arcs


def expected_result(values: Sequence[int] | None,
                    input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    parsed = _read(values, input_is_null, input_length)
    if parsed is None:
        return -1
    n, arcs = parsed
    net_inflow = [0] * n

    def search(index: int) -> bool:
        if index == len(arcs):
            return all(balance == 0 for balance in net_inflow)
        source, target, low, high = arcs[index]
        for amount in range(low, high + 1):
            net_inflow[source] -= amount
            net_inflow[target] += amount
            if search(index + 1):
                net_inflow[source] += amount
                net_inflow[target] -= amount
                return True
            net_inflow[source] += amount
            net_inflow[target] -= amount
        return False

    return int(search(0))
