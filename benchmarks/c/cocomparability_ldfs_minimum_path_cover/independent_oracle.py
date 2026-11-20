"""Subset-DP minimum path partition reference, independent of LDFS+ and RMN."""

from __future__ import annotations

from collections.abc import Sequence

try:
    from .primary_oracle import (
        INVALID_RESULT, MAX_PARSEABLE_INPUT_LENGTH, MAX_VERTICES,
        MIN_VERTICES,
    )
except ImportError:
    from primary_oracle import (
        INVALID_RESULT, MAX_PARSEABLE_INPUT_LENGTH, MAX_VERTICES,
        MIN_VERTICES,
    )


def _valid(values: Sequence[int] | None, input_is_null: bool,
           input_length: int | None) -> tuple[int, list[int]] | None:
    if (type(input_is_null) is not bool or input_is_null or values is None
            or not isinstance(values, (list, tuple))
            or not 1 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
            or (input_length is not None
                and (type(input_length) is not int or input_length != len(values)))
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return None
    n = values[0]
    if not MIN_VERTICES <= n <= MAX_VERTICES or len(values) != 1 + 2 * n:
        return None
    rows = list(values[1:1 + n])
    order = list(values[1 + n:])
    limit = (1 << n) - 1
    if any(row < 0 or row & ~limit or row & (1 << v)
           for v, row in enumerate(rows)):
        return None
    if any(((rows[u] >> v) & 1) != ((rows[v] >> u) & 1)
           for u in range(n) for v in range(n)):
        return None
    if sorted(order) != list(range(n)):
        return None
    reached = 1
    todo = reached
    while todo:
        bit = todo & -todo
        v = bit.bit_length() - 1
        todo ^= bit
        fresh = rows[v] & ~reached
        reached |= fresh
        todo |= fresh
    if reached != limit:
        return None
    pos = [0] * n
    for i, v in enumerate(order):
        pos[v] = i
    for a in range(n):
        for b in range(a + 1, n):
            for c in range(b + 1, n):
                u, v, w = order[a], order[b], order[c]
                if ((rows[u] >> w) & 1) and not (
                    ((rows[u] >> v) & 1) or ((rows[v] >> w) & 1)
                ):
                    return None
    return n, rows


def expected_result(values: Sequence[int] | None, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    parsed = _valid(values, input_is_null, input_length)
    if parsed is None:
        return INVALID_RESULT
    n, rows = parsed
    state_count = 1 << n
    end_vertices = [0] * state_count
    for subset in range(1, state_count):
        bits = subset
        while bits:
            bit = bits & -bits
            endpoint = bit.bit_length() - 1
            rest = subset ^ bit
            if not rest or (end_vertices[rest] & rows[endpoint]):
                end_vertices[subset] |= bit
            bits ^= bit

    best = [n + 1] * state_count
    best[0] = 0
    for covered in range(1, state_count):
        anchor = covered & -covered
        path = covered
        while path:
            if path & anchor and end_vertices[path]:
                candidate = 1 + best[covered ^ path]
                if candidate < best[covered]:
                    best[covered] = candidate
            path = (path - 1) & covered
    return best[-1]
