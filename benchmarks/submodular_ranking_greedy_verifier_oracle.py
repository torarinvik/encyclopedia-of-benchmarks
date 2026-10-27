"""Independent integer-rational checker for submodular-ranking greedy."""

from __future__ import annotations

import struct
from collections.abc import Sequence


def _valid_table(t: list[int], n: int) -> bool:
    full = (1 << n) - 1
    if t[0] != 0 or t[full] != 8 or any(x < 0 or x > 8 for x in t):
        return False
    for a in range(1 << n):
        for bit in range(n):
            if a & (1 << bit):
                continue
            if t[a] > t[a | (1 << bit)]:
                return False
            marginal = t[a | (1 << bit)] - t[a]
            b = a | (1 << bit)
            for other in range(n):
                if b & (1 << other):
                    continue
                b2 = b | (1 << other)
                if marginal < t[b2] - t[b]:
                    return False
    return True


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
    if not 2 <= len(values) <= 131 or any(
            type(v) is not int or not -(1 << 63) <= v < (1 << 63) for v in values):
        return -1, b""
    n, m = values[0], values[1]
    if not 1 <= n <= 5 or not 1 <= m <= 4 or len(values) != 2 + m * (1 << n):
        return -1, b""
    q = 1 << n
    tables = [list(values[2 + j*q:2 + (j+1)*q]) for j in range(m)]
    if not all(_valid_table(t, n) for t in tables):
        return -1, b""
    current_mask = 0
    order: list[int] = []
    first = [0] * m
    objective = 0
    for time in range(1, n + 1):
        winner = -1
        winning_num, winning_den = -1, 1
        for e in range(n):
            if current_mask & (1 << e):
                continue
            # Sum fractions with an unreduced common denominator.  Since the
            # workload has at most four functions and denominators <= 8, this
            # stays comfortably within signed 64-bit arithmetic.
            num, den = 0, 1
            for tab in tables:
                f = tab[current_mask]
                if f == 8:
                    continue
                d = 8 - f
                delta = tab[current_mask | (1 << e)] - f
                num, den = num*d + delta*den, den*d
            if winner < 0 or num * winning_den > winning_num * den:
                winner, winning_num, winning_den = e, num, den
        current_mask |= 1 << winner
        order.append(winner)
        for j, tab in enumerate(tables):
            if first[j] == 0 and tab[current_mask] == 8:
                first[j] = time
                objective += time
    output = b"".join(struct.pack("<q", x) for x in (objective, *order, *first))
    if output_is_null or capacity is not None and capacity < len(output):
        return -2, b""
    return len(output), output
