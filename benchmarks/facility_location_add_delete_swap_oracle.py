"""Deterministic add/delete/swap local search for uncapacitated FL."""

from __future__ import annotations

import struct
from collections.abc import Sequence

MAX_N = 7
MAX_M = 7
MAX_TOTAL = 8
MAX_VALID_INPUT_LENGTH = 2 + MAX_TOTAL * MAX_TOTAL + MAX_M + 1
MAX_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_OUTPUT_BYTES = 8 * (2 + MAX_TOTAL)


def _lex_less(a: int, b: int, m: int) -> bool:
    """Compare sorted facility-ID lists represented by masks."""
    ia = ib = 0
    while True:
        while ia < m and not (a >> ia) & 1:
            ia += 1
        while ib < m and not (b >> ib) & 1:
            ib += 1
        if ia == m or ib == m:
            return ia == m and ib != m
        if ia != ib:
            return ia < ib
        ia += 1
        ib += 1


def _cost(n: int, m: int, d: list[int], opening: list[int], mask: int) -> int:
    total = sum(opening[j] for j in range(m) if mask >> j & 1)
    for user in range(n):
        total += min(d[user * (n + m) + n + j] for j in range(m) if mask >> j & 1)
    return total


def _decode(values: Sequence[int] | None, input_length: int | None,
            input_is_null: bool) -> tuple[int, int, list[int], list[int], int] | None:
    if input_is_null or values is None or not isinstance(values, (list, tuple)):
        return None
    if len(values) < 4 or len(values) > MAX_INPUT_LENGTH or any(
            type(v) is not int or not -(1 << 63) <= v < (1 << 63) for v in values):
        return None
    if input_length is not None and (type(input_length) is not int or input_length != len(values)):
        return None
    n, m = values[:2]
    if not (1 <= n <= MAX_N and 1 <= m <= MAX_M and n + m <= MAX_TOTAL):
        return None
    q = n + m
    expected_len = 2 + q * q + m + 1
    if len(values) != expected_len:
        return None
    d = list(values[2:2 + q*q])
    if any(x < 0 or x > 1000 for x in d):
        return None
    for i in range(q):
        if d[i*q+i] != 0:
            return None
        for j in range(q):
            if i != j and d[i*q+j] <= 0:
                return None
            if d[i*q+j] != d[j*q+i]:
                return None
            for k in range(q):
                if d[i*q+j] > d[i*q+k] + d[k*q+j]:
                    return None
    opening = list(values[2 + q*q:2 + q*q + m])
    if any(x < 0 or x > 1000 for x in opening):
        return None
    initial = values[-1]
    if not 0 < initial < (1 << m):
        return None
    return n, m, d, opening, initial


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or capacity is not None and (type(capacity) is not int or capacity < 0)
            or input_length is not None and (type(input_length) is not int or input_length < 0)
            or input_is_null and values not in (None, [], ())):
        return -1, b""
    decoded = _decode(values, input_length, input_is_null)
    if decoded is None:
        return -1, b""
    n, m, d, opening, current = decoded
    current_cost = _cost(n, m, d, opening, current)
    while True:
        best, best_cost = current, current_cost
        for j in range(m):
            bit = 1 << j
            if not current & bit:
                candidate = current | bit
                cost = _cost(n, m, d, opening, candidate)
                if cost < current_cost and (cost < best_cost or cost == best_cost and _lex_less(candidate, best, m)):
                    best, best_cost = candidate, cost
            elif current & ~bit:
                candidate = current & ~bit
                cost = _cost(n, m, d, opening, candidate)
                if cost < current_cost and (cost < best_cost or cost == best_cost and _lex_less(candidate, best, m)):
                    best, best_cost = candidate, cost
                for k in range(m):
                    other = 1 << k
                    if current & other:
                        continue
                    candidate = (current & ~bit) | other
                    cost = _cost(n, m, d, opening, candidate)
                    if cost < current_cost and (cost < best_cost or cost == best_cost and _lex_less(candidate, best, m)):
                        best, best_cost = candidate, cost
        # The chapter's stopping criterion is a near-improvement factor. This
        # bounded profile fixes epsilon=0.1.
        if best_cost * 10 >= current_cost * 9:
            break
        current, current_cost = best, best_cost
    facilities = [j for j in range(m) if current >> j & 1]
    assignments = [min(facilities, key=lambda j: (d[u*(n+m)+n+j], j)) for u in range(n)]
    values_out = (current_cost, len(facilities), *facilities, *assignments)
    output = b"".join(struct.pack("<q", x) for x in values_out)
    if output_is_null or capacity is not None and capacity < len(output):
        return -2, b""
    return len(output), output
