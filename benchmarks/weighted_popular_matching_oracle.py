"""Primary exact oracle for weighted popularity over bounded assignments."""

from __future__ import annotations

import itertools
import struct
from collections.abc import Sequence

MAX_INPUT = 22


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or capacity is not None and (type(capacity) is not int or capacity < 0)
            or input_length is not None and (type(input_length) is not int or not 0 <= input_length <= MAX_INPUT)
            or input_is_null and values not in (None, [], ())
            or not input_is_null and values is not None and input_length is not None and input_length != len(values)):
        return -1, b""
    if input_is_null or values is None or not isinstance(values, (list, tuple)):
        return -1, b""
    if len(values) < 4 or len(values) > MAX_INPUT or any(type(x) is not int or not -(1 << 63) <= x < (1 << 63) for x in values):
        return -1, b""
    n, m = values[:2]
    if not 1 <= n <= 4 or not 1 <= m <= 4 or len(values) != 2 + n + n * m:
        return -1, b""
    weights = values[2:2 + n]
    ranks = [tuple(values[2 + n + i * m:2 + n + (i + 1) * m]) for i in range(n)]
    if any(not 1 <= weight <= 1000 for weight in weights):
        return -1, b""
    if any(sorted(row) != list(range(m)) for row in ranks):
        return -1, b""

    feasible = [a for a in itertools.product(range(-1, m), repeat=n)
                if len([item for item in a if item >= 0]) == len(set(item for item in a if item >= 0))]
    best: tuple[int, ...] | None = None
    best_card = -1
    for candidate in feasible:
        is_popular = True
        for rival in feasible:
            score = 0
            for i in range(n):
                own_rank = m if candidate[i] < 0 else ranks[i][candidate[i]]
                rival_rank = m if rival[i] < 0 else ranks[i][rival[i]]
                if rival_rank < own_rank:
                    score += weights[i]
                elif rival_rank > own_rank:
                    score -= weights[i]
            if score > 0:
                is_popular = False
                break
        if is_popular:
            cardinality = sum(item >= 0 for item in candidate)
            if cardinality > best_card or cardinality == best_card and (best is None or candidate < best):
                best_card = cardinality
                best = candidate
    fields = [0, 0, *([-1] * n)] if best is None else [1, best_card, *best]
    payload = b"".join(struct.pack("<q", field) for field in fields)
    if output_is_null or capacity is not None and capacity < len(payload):
        return -2, b""
    return len(payload), payload
