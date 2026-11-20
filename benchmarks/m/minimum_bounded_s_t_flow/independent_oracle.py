"""Independent exhaustive edge-flow oracle for minimum bounded s-t flow."""

from __future__ import annotations

from collections.abc import Sequence


def _parse(values: Sequence[int] | None, input_is_null: bool,
           input_length: int | None):
    # Intentionally separate from the reduction oracle's parser.
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple))
            or not 4 <= len(values) <= 37
            or any(type(item) is not int or not -(1 << 63) <= item < (1 << 63)
                   for item in values)):
        return None
    if input_length is not None and (
            type(input_length) is not int or input_length != len(values)):
        return None
    n, count, source, sink = values[:4]
    if (not 2 <= n <= 6 or not 0 <= count <= 8
            or not 0 <= source < n or not 0 <= sink < n or source == sink
            or len(values) != 4 + 4 * count):
        return None
    arcs = []
    for index in range(count):
        u, v, lower, upper = values[4 + 4 * index:8 + 4 * index]
        if (not 0 <= u < n or not 0 <= v < n
                or not 0 <= lower <= upper <= 2):
            return None
        arcs.append((u, v, lower, upper))
    return n, source, sink, arcs


def expected_result(values: Sequence[int] | None,
                    input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    parsed = _parse(values, input_is_null, input_length)
    if parsed is None:
        return -1
    n, source, sink, arcs = parsed
    net_outflow = [0] * n
    best: int | None = None

    def enumerate_assignments(index: int) -> None:
        nonlocal best
        if index == len(arcs):
            value = net_outflow[source]
            if (value >= 0 and net_outflow[sink] == -value
                    and all(net_outflow[v] == 0 for v in range(n)
                            if v != source and v != sink)):
                if best is None or value < best:
                    best = value
            return
        u, v, lower, upper = arcs[index]
        for amount in range(lower, upper + 1):
            net_outflow[u] += amount
            net_outflow[v] -= amount
            enumerate_assignments(index + 1)
            net_outflow[u] -= amount
            net_outflow[v] += amount

    enumerate_assignments(0)
    return -2 if best is None else best
