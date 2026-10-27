"""Exact bounded oracle for optimistic rate-based flow-control updates."""

from __future__ import annotations

import struct
from collections.abc import Sequence
from fractions import Fraction

MAX_N = 3
MAX_LINKS = 4
MAX_UPDATES = 6
MAX_INPUT = 20
MAX_INPUT_LENGTH = MAX_INPUT
MAX_OUTPUT_BYTES = 48


def _parse(values: Sequence[int] | None):
    if (not isinstance(values, (list, tuple)) or len(values) < 7 or len(values) > MAX_INPUT
            or any(type(x) is not int or not -(1 << 63) <= x < (1 << 63) for x in values)):
        return None
    n, links, mode, updates = values[:4]
    if not 2 <= n <= MAX_N or not 1 <= links <= MAX_LINKS or mode not in range(4) or not 1 <= updates <= MAX_UPDATES:
        return None
    if len(values) != 4 + links + n * links:
        return None
    capacities = list(values[4:4+links])
    if any(not 1 <= cap <= 16 for cap in capacities):
        return None
    raw = values[4+links:]
    path = [list(raw[i*links:(i+1)*links]) for i in range(n)]
    if any(bit not in (0, 1) for row in path for bit in row) or any(not any(row) for row in path):
        return None
    return n, links, mode, updates, capacities, path


def _largest_link_rate(session: int, link: int, capacities: list[int],
                       path: list[list[int]], rates: list[Fraction]) -> Fraction:
    ceiling = Fraction(capacities[link])
    others = [rates[j] for j in range(len(rates)) if j != session and path[j][link]]
    # Enumerate each possible saturated/unsaturated partition instead of the
    # source oracle's sorted-level sweep.
    best: Fraction | None = None
    for mask in range(1 << len(others)):
        fixed = [rate for bit, rate in enumerate(others) if mask & (1 << bit)]
        active = [rate for bit, rate in enumerate(others) if not mask & (1 << bit)]
        candidate = (ceiling - sum(fixed, Fraction(0))) / (1 + len(active))
        if candidate < rates[session] or any(rate > candidate for rate in fixed) or any(rate < candidate for rate in active):
            continue
        if candidate + sum((min(rate, candidate) for rate in others), Fraction(0)) != ceiling:
            continue
        if best is None or candidate > best:
            best = candidate
    if best is None:
        raise ValueError("no feasible exact water-level candidate")
    return best


def _choose(mode: int, step: int, n: int, links: int, capacities: list[int],
            path: list[list[int]], rates: list[Fraction]) -> int:
    if mode == 0:
        return step % n
    if mode == 1:
        return min(range(n), key=lambda s: (rates[s], s))
    if mode == 2:
        for s in range(n):
            neighbors = [j for j in range(n) if j != s and any(path[s][e] and path[j][e] for e in range(links))]
            if all((rates[s], s) <= (rates[j], j) for j in neighbors):
                return s
        return min(range(n), key=lambda s: (rates[s], s))
    loads = [sum((rates[s] for s in range(n) if path[s][e]), Fraction(0)) for e in range(links)]
    used = [e for e in range(links) if any(path[s][e] for s in range(n))]
    link = min(used, key=lambda e: (-loads[e] / capacities[e], e))
    return min(s for s in range(n) if path[s][link])


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
    if input_is_null or values is None:
        return -1, b""
    parsed = _parse(values)
    if parsed is None:
        return -1, b""
    n, links, mode, updates, capacities, path = parsed
    output_bytes = 16 * n
    if output_is_null or capacity is not None and capacity < output_bytes:
        return -2, b""
    rates = [Fraction(0) for _ in range(n)]
    try:
        for step in range(updates):
            session = _choose(mode, step, n, links, capacities, path, rates)
            candidates = [(_largest_link_rate(session, e, capacities, path, rates), e)
                          for e in range(links) if path[session][e]]
            new_rate, bottleneck = min(candidates, key=lambda pair: (pair[0], pair[1]))
            rates[session] = new_rate
            for other in range(n):
                if other != session and path[other][bottleneck] and rates[other] > new_rate:
                    rates[other] = new_rate
    except ValueError:
        return -1, b""
    data = b"".join(struct.pack("<qq", rate.numerator, rate.denominator) for rate in rates)
    return len(data), data
