"""Independent key/set formulation for the bounded Király MAX-SMTI profile."""

from __future__ import annotations

import struct
from collections.abc import Sequence

MAX_M = 6
MAX_W = 6
MAX_INPUT = 74
MAX_INPUT_LENGTH = MAX_INPUT
MAX_OUTPUT_BYTES = 8 * MAX_M


def _decode(values: Sequence[int] | None):
    if (not isinstance(values, (list, tuple)) or len(values) < 4 or len(values) > MAX_INPUT
            or any(type(x) is not int or not -(1 << 63) <= x < (1 << 63) for x in values)):
        return None
    m, w = values[:2]
    if not 1 <= m <= MAX_M or not 1 <= w <= MAX_W or len(values) != 2 + 2 * m * w:
        return None
    men = [tuple(values[2 + i*w:2 + (i+1)*w]) for i in range(m)]
    offset = 2 + m*w
    women = [tuple(values[offset + i*m:offset + (i+1)*m]) for i in range(w)]
    if any(x < -1 or x >= MAX_W for row in men for x in row):
        return None
    if any(x < -1 or x >= MAX_M for row in women for x in row):
        return None
    if any((men[i][j] == -1) != (women[j][i] == -1) for i in range(m) for j in range(w)):
        return None
    return m, w, men, women


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
    decoded = _decode(values)
    if decoded is None:
        return -1, b""
    m, w, men, women = decoded
    required = 8 * m
    if output_is_null or capacity is not None and capacity < required:
        return -2, b""

    acceptable = [{j for j, rank in enumerate(men[i]) if rank >= 0} for i in range(m)]
    remaining = [set(options) for options in acceptable]
    engaged_to = [-1] * m
    occupied_by = [-1] * w
    # 0 = lad, 1 = bachelor, 2 = old bachelor.
    stage = [0] * m

    def suitor_order(i: int, j: int) -> tuple[int, int, int]:
        # Weak rank, then maiden-before-engaged, then the profile's ID tie-break.
        return men[i][j], int(occupied_by[j] >= 0), j

    def uncertain(i: int) -> bool:
        fiance = engaged_to[i]
        if stage[i] != 0 or fiance < 0:
            return False
        return any(men[i][j] < men[i][fiance] or
                   (men[i][j] == men[i][fiance] and occupied_by[j] < 0 and occupied_by[fiance] >= 0)
                   for j in remaining[i] if j != fiance)

    def accept_key(j: int, i: int) -> tuple[int, int, int]:
        # For a non-flighty woman: weak rank, bachelor-before-lad, then ID.
        return women[j][i], -stage[i], i

    rounds = 0
    while True:
        rounds += 1
        if rounds > 3 * m * w + 2 * m + 1:
            return -1, b""
        free = [i for i in range(m) if stage[i] != 2 and engaged_to[i] < 0]
        if not free:
            break
        i = free[0]
        if not remaining[i]:
            if stage[i] == 0:
                stage[i] = 1
                remaining[i] = acceptable[i].copy()
            else:
                stage[i] = 2
            continue
        j = min(remaining[i], key=lambda x: suitor_order(i, x))
        incumbent = occupied_by[j]
        if incumbent < 0:
            engaged_to[i] = j
            occupied_by[j] = i
            continue
        old_is_uncertain = uncertain(incumbent)
        prefer_new = old_is_uncertain or accept_key(j, i) < accept_key(j, incumbent)
        if prefer_new:
            engaged_to[incumbent] = -1
            if not old_is_uncertain:
                remaining[incumbent].discard(j)
            occupied_by[j] = i
            engaged_to[i] = j
        else:
            remaining[i].discard(j)

    data = b"".join(struct.pack("<q", woman) for woman in engaged_to)
    return len(data), data
