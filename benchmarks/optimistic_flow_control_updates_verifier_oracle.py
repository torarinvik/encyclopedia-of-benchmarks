"""Independent exact-rate verifier using link-level breakpoint scans."""

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


def _decode(data: Sequence[int] | None):
    if (not isinstance(data, (list, tuple)) or len(data) < 7 or len(data) > MAX_INPUT
            or any(type(x) is not int or not -(1 << 63) <= x < (1 << 63) for x in data)):
        return None
    n, links, policy, rounds = data[:4]
    if n not in (2, 3) or not 1 <= links <= 4 or policy not in (0, 1, 2, 3) or not 1 <= rounds <= 6:
        return None
    if len(data) != 4 + links + n*links:
        return None
    caps = tuple(data[4:4+links])
    if any(c <= 0 or c > 16 for c in caps):
        return None
    incidence = tuple(tuple(data[4+links+i*links:4+links+(i+1)*links]) for i in range(n))
    if any(bit not in (0, 1) for row in incidence for bit in row) or any(sum(row) == 0 for row in incidence):
        return None
    return n, links, policy, rounds, caps, incidence


def _link_ceiling(i: int, e: int, caps: tuple[int, ...], incidence: tuple[tuple[int, ...], ...],
                  rates: list[Fraction]) -> Fraction:
    contenders = [j for j in range(len(rates)) if j != i and incidence[j][e]]
    breakpoints = sorted({rates[j] for j in contenders if rates[j] > rates[i]})
    frozen = sum((rates[j] for j in contenders if rates[j] <= rates[i]), Fraction(0))
    level = rates[i]
    remaining = 1 + sum(rates[j] > level for j in contenders)
    while True:
        top = (Fraction(caps[e]) - frozen) / remaining
        if top < level:
            raise ValueError("infeasible rate state")
        next_point = next((q for q in breakpoints if q > level), None)
        if next_point is None or top <= next_point:
            return top
        count = sum(rates[j] == next_point for j in contenders)
        frozen += count * next_point
        remaining -= count
        level = next_point


def _policy(policy: int, turn: int, n: int, links: int, caps: tuple[int, ...],
            inc: tuple[tuple[int, ...], ...], rates: list[Fraction]) -> int:
    if policy == 0:
        return turn % n
    if policy == 1:
        low = min(rates)
        return next(i for i, value in enumerate(rates) if value == low)
    if policy == 2:
        for i in range(n):
            neighbor_ids = [j for j in range(n) if j != i and any(inc[i][e] and inc[j][e] for e in range(links))]
            if not any(rates[j] < rates[i] or (rates[j] == rates[i] and j < i) for j in neighbor_ids):
                return i
        return min(range(n), key=lambda i: (rates[i], i))
    active_links = [e for e in range(links) if any(inc[i][e] for i in range(n))]
    load = [sum((rates[i] for i in range(n) if inc[i][e]), Fraction(0)) for e in range(links)]
    chosen_link = active_links[0]
    for e in active_links[1:]:
        if load[e] / caps[e] > load[chosen_link] / caps[chosen_link]:
            chosen_link = e
    return next(i for i in range(n) if inc[i][chosen_link])


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
    spec = _decode(values)
    if spec is None:
        return -1, b""
    n, links, policy, rounds, caps, incidence = spec
    required = 16 * n
    if output_is_null or capacity is not None and capacity < required:
        return -2, b""
    rates = [Fraction(0) for _ in range(n)]
    try:
        for turn in range(rounds):
            i = _policy(policy, turn, n, links, caps, incidence, rates)
            options = [(_link_ceiling(i, e, caps, incidence, rates), e)
                       for e in range(links) if incidence[i][e]]
            new_rate, limiting = min(options)
            rates[i] = new_rate
            for j in range(n):
                if j != i and incidence[j][limiting] and rates[j] > new_rate:
                    rates[j] = new_rate
    except ValueError:
        return -1, b""
    packed = b"".join(struct.pack("<qq", rate.numerator, rate.denominator) for rate in rates)
    return len(packed), packed
