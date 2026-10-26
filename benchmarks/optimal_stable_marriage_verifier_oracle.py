"""Enumeration-based verifier for minimum-regret stable marriage."""

from __future__ import annotations

import itertools
import struct
from collections.abc import Sequence

MAX_N = 8
MAX_INPUT = 1 + 2 * MAX_N * MAX_N


def _canonical_optimum(men: list[list[int]], women: list[list[int]]) -> tuple[int, ...]:
    n = len(men)
    men_rank = [[0] * n for _ in range(n)]
    women_rank = [[0] * n for _ in range(n)]
    for person, row in enumerate(men):
        for rank, other in enumerate(row):
            men_rank[person][other] = rank
    for person, row in enumerate(women):
        for rank, other in enumerate(row):
            women_rank[person][other] = rank
    best_regret = n
    best_assignment: tuple[int, ...] | None = None
    best_men_ranks: tuple[int, ...] | None = None
    for assignment in itertools.permutations(range(n)):
        inverse = [0] * n
        for man, woman in enumerate(assignment):
            inverse[woman] = man
        if any(men_rank[man][woman] < men_rank[man][assignment[man]]
               and women_rank[woman][man] < women_rank[woman][inverse[woman]]
               for man in range(n) for woman in range(n)):
            continue
        regret = max((men_rank[man][woman] for man, woman in enumerate(assignment)),
                     default=0)
        regret = max(regret, max((women_rank[woman][man] for man, woman in enumerate(assignment)), default=0))
        rank_vector = tuple(men_rank[man][woman] for man, woman in enumerate(assignment))
        if regret < best_regret or (regret == best_regret and (best_men_ranks is None or rank_vector < best_men_ranks)):
            best_regret = regret
            best_assignment = assignment
            best_men_ranks = rank_vector
    return best_assignment if best_assignment is not None else ()


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or capacity is not None and (type(capacity) is not int or capacity < 0)
            or input_length is not None and (type(input_length) is not int or not 0 <= input_length <= MAX_INPUT)):
        return -1, b""
    if input_is_null or values is None or not isinstance(values, (list, tuple)):
        if input_is_null and values not in (None, [], ()):
            return -1, b""
        return -1, b""
    if input_length is not None and input_length != len(values):
        return -1, b""
    if not 1 <= len(values) <= MAX_INPUT or any(type(value) is not int or not -(1 << 63) <= value <= (1 << 63) - 1 for value in values):
        return -1, b""
    n = values[0]
    if not 0 <= n <= MAX_N or len(values) != 1 + 2 * n * n:
        return -1, b""
    men = [list(values[1 + man * n:1 + (man + 1) * n]) for man in range(n)]
    start = 1 + n * n
    women = [list(values[start + woman * n:start + (woman + 1) * n]) for woman in range(n)]
    if any(sorted(row) != list(range(n)) for row in men + women):
        return -1, b""
    required = 16 * n
    if output_is_null or capacity is not None and capacity < required:
        return -2, b""
    assignment = _canonical_optimum(men, women)
    payload = b"".join(struct.pack("<q", value) for man, woman in enumerate(assignment) for value in (man, woman))
    return len(payload), payload
