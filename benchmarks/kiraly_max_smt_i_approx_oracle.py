"""Király's bounded MAX-SMTI 3/2-approximation profile oracle."""

from __future__ import annotations

import struct
from collections.abc import Sequence

MAX_M = 6
MAX_W = 6
MAX_INPUT = 74
MAX_INPUT_LENGTH = MAX_INPUT
MAX_OUTPUT_BYTES = 8 * MAX_M


def _parse(values: Sequence[int] | None):
    if (not isinstance(values, (list, tuple)) or len(values) < 4 or len(values) > MAX_INPUT
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return None
    m, w = values[0], values[1]
    if not 1 <= m <= MAX_M or not 1 <= w <= MAX_W or len(values) != 2 + 2 * m * w:
        return None
    men_rank = [list(values[2 + man * w:2 + (man + 1) * w]) for man in range(m)]
    offset = 2 + m * w
    women_rank = [list(values[offset + woman * m:offset + (woman + 1) * m]) for woman in range(w)]
    if any(rank < -1 or rank >= MAX_W for row in men_rank for rank in row):
        return None
    if any(rank < -1 or rank >= MAX_M for row in women_rank for rank in row):
        return None
    if any((men_rank[man][woman] >= 0) != (women_rank[woman][man] >= 0)
           for man in range(m) for woman in range(w)):
        return None
    return m, w, men_rank, women_rank


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
    m, w, men_rank, women_rank = parsed
    output_bytes = 8 * m
    if output_is_null or capacity is not None and capacity < output_bytes:
        return -2, b""

    live = [[men_rank[man][woman] >= 0 for woman in range(w)] for man in range(m)]
    assignment = [-1] * m
    woman_partner = [-1] * w
    # 0 lad, 1 bachelor, 2 old bachelor
    status = [0] * m

    def man_prefers(man: int, a: int, b: int) -> bool:
        ra, rb = men_rank[man][a], men_rank[man][b]
        if ra != rb:
            return ra < rb
        a_maiden, b_maiden = woman_partner[a] < 0, woman_partner[b] < 0
        if a_maiden != b_maiden:
            return a_maiden
        return a < b

    def is_uncertain(man: int) -> bool:
        if status[man] != 0 or assignment[man] < 0:
            return False
        fiance = assignment[man]
        return any(live[man][woman] and woman != fiance and
                   (men_rank[man][woman] < men_rank[man][fiance] or
                    (men_rank[man][woman] == men_rank[man][fiance] and
                     woman_partner[woman] < 0 and woman_partner[fiance] >= 0))
                   for woman in range(w))

    def woman_prefers(woman: int, candidate: int, incumbent: int, incumbent_uncertain: bool) -> bool:
        # The active proposer is certain; a flighty woman prefers him regardless of original rank.
        if incumbent_uncertain:
            return True
        rc, ri = women_rank[woman][candidate], women_rank[woman][incumbent]
        if rc != ri:
            return rc < ri
        if status[candidate] != status[incumbent]:
            return status[candidate] > status[incumbent]
        return candidate < incumbent

    steps = 0
    while True:
        steps += 1
        if steps > 3 * m * w + 2 * m + 1:
            return -1, b""
        proposer = next((man for man in range(m)
                        if status[man] != 2 and assignment[man] < 0), None)
        if proposer is None:
            break
        choices = [woman for woman in range(w) if live[proposer][woman]]
        if not choices:
            if status[proposer] == 0:
                status[proposer] = 1
                live[proposer] = [men_rank[proposer][woman] >= 0 for woman in range(w)]
            else:
                status[proposer] = 2
            continue
        favorite = choices[0]
        for woman in choices[1:]:
            if man_prefers(proposer, woman, favorite):
                favorite = woman
        incumbent = woman_partner[favorite]
        if incumbent < 0:
            assignment[proposer] = favorite
            woman_partner[favorite] = proposer
            continue
        incumbent_uncertain = is_uncertain(incumbent)
        if woman_prefers(favorite, proposer, incumbent, incumbent_uncertain):
            assignment[incumbent] = -1
            woman_partner[favorite] = -1
            if not incumbent_uncertain:
                live[incumbent][favorite] = False
            assignment[proposer] = favorite
            woman_partner[favorite] = proposer
        else:
            live[proposer][favorite] = False

    output = b"".join(struct.pack("<q", woman) for woman in assignment)
    return len(output), output
