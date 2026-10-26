"""Thresholded deferred-acceptance oracle for minimum-regret stable marriage."""

from __future__ import annotations

import struct
from collections.abc import Sequence

MAX_N = 8
MAX_INPUT = 1 + 2 * MAX_N * MAX_N
MAX_OUTPUT_BYTES = 16 * MAX_N
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1


def _threshold_matching(men: list[list[int]], women_rank: list[list[int]], threshold: int) -> tuple[int, ...] | None:
    n = len(men)
    women_partner = [-1] * n
    man_partner = [-1] * n
    next_rank = [0] * n
    queue = list(range(n))
    head = 0
    while head < len(queue):
        man = queue[head]
        head += 1
        while next_rank[man] < n:
            woman = men[man][next_rank[man]]
            rank = next_rank[man]
            next_rank[man] += 1
            if rank > threshold or women_rank[woman][man] > threshold:
                continue
            incumbent = women_partner[woman]
            if incumbent < 0 or women_rank[woman][man] < women_rank[woman][incumbent]:
                women_partner[woman] = man
                man_partner[man] = woman
                if incumbent >= 0:
                    man_partner[incumbent] = -1
                    queue.append(incumbent)
                break
        # If no acceptable woman remains, this man stays unmatched at this threshold.
    if any(woman < 0 for woman in man_partner):
        return None
    return tuple(man_partner)


def _minimum_regret(men: list[list[int]], women: list[list[int]]) -> tuple[int, ...]:
    women_rank = [[0] * len(men) for _ in men]
    for woman, row in enumerate(women):
        for rank, man in enumerate(row):
            women_rank[woman][man] = rank
    for threshold in range(len(men)):
        assignment = _threshold_matching(men, women_rank, threshold)
        if assignment is not None:
            return assignment
    return ()


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
    if not 1 <= len(values) <= MAX_INPUT or any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values):
        return -1, b""
    n = values[0]
    if not 0 <= n <= MAX_N or len(values) != 1 + 2 * n * n:
        return -1, b""
    men = [list(values[1 + man * n:1 + (man + 1) * n]) for man in range(n)]
    women_start = 1 + n * n
    women = [list(values[women_start + woman * n:women_start + (woman + 1) * n]) for woman in range(n)]
    if any(sorted(row) != list(range(n)) for row in men + women):
        return -1, b""
    if type(output_is_null) is not bool or (capacity is not None and (type(capacity) is not int or capacity < 0)):
        return -1, b""
    required = 16 * n
    if output_is_null or capacity is not None and capacity < required:
        return -2, b""
    assignment = _minimum_regret(men, women)
    payload = b"".join(struct.pack("<q", identifier)
                       for man, woman in enumerate(assignment)
                       for identifier in (man, woman))
    return len(payload), payload
