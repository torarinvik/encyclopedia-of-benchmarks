"""Primary deferred-acceptance oracle for Encyclopedia chapter DOI 805."""

from __future__ import annotations

import struct
from collections.abc import Sequence

MAX_N = 6
MAX_INPUT_LENGTH = 73
MAX_OUTPUT_BYTES = 104
MAX_WORKSPACE_BYTES = 2048


def _parse(values: Sequence[int] | None):
    if (not isinstance(values, (list, tuple)) or not 1 <= len(values) <= MAX_INPUT_LENGTH
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return None
    n = values[0]
    if not 1 <= n <= MAX_N or len(values) != 1 + 2 * n * n:
        return None
    split = 1 + n * n
    men = [list(values[1 + man * n:1 + (man + 1) * n]) for man in range(n)]
    women = [list(values[split + woman * n:split + (woman + 1) * n]) for woman in range(n)]
    for man in range(n):
        for woman in range(n):
            mr, wr = men[man][woman], women[woman][man]
            if (not 0 <= mr <= n or not 0 <= wr <= n or (mr > 0) != (wr > 0)):
                return None
    return n, men, women


def _run(n: int, men_rank: list[list[int]], women_rank: list[list[int]]) -> list[int]:
    preferences = [sorted((woman for woman in range(n) if men_rank[man][woman] > 0),
                          key=lambda woman: (men_rank[man][woman], woman))
                   for man in range(n)]
    man_partner = [-1] * n
    woman_partner = [-1] * n
    next_choice = [0] * n
    while True:
        free = next((man for man in range(n)
                     if man_partner[man] < 0 and next_choice[man] < len(preferences[man])), None)
        if free is None:
            break
        woman = preferences[free][next_choice[free]]
        next_choice[free] += 1
        incumbent = woman_partner[woman]
        if (incumbent < 0 or (women_rank[woman][free], free)
                < (women_rank[woman][incumbent], incumbent)):
            woman_partner[woman] = free
            man_partner[free] = woman
            if incumbent >= 0:
                man_partner[incumbent] = -1
    pairs = [(man, woman) for man, woman in enumerate(man_partner) if woman >= 0]
    words = [len(pairs), *(item for pair in pairs for item in pair)]
    return words


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or capacity is not None and (type(capacity) is not int or capacity < 0)
            or input_length is not None and (type(input_length) is not int
                                             or not 0 <= input_length <= MAX_INPUT_LENGTH)
            or input_is_null and values not in (None, [], ())
            or not input_is_null and values is not None and input_length is not None
            and input_length != len(values)):
        return -1, b""
    if input_is_null or values is None:
        return -1, b""
    parsed = _parse(values)
    if parsed is None:
        return -1, b""
    n, men, women = parsed
    words = _run(n, men, women)
    payload = struct.pack("<" + "q" * len(words), *words)
    if output_is_null or capacity is not None and capacity < len(payload):
        return -2, b""
    return len(payload), payload
