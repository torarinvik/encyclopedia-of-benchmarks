"""Independent oracle for the bounded DIS R-tree partitionEntries helper."""
from __future__ import annotations

from collections.abc import Sequence

MIN_FAN = 2
MAX_FAN = 8
MIN_COORDINATE = -8
MAX_COORDINATE = 8
MAX_INPUT_LENGTH = 1 + 8 * (MAX_FAN + 1)
MAX_PARSEABLE_INPUT_LENGTH = MAX_INPUT_LENGTH + 1
INVALID_RESULT = -1


def _valid_box(values: Sequence[int], at: int) -> bool:
    for d in range(4):
        lo, hi = values[at + d], values[at + 4 + d]
        if not MIN_COORDINATE <= lo <= MAX_COORDINATE or not MIN_COORDINATE <= hi <= MAX_COORDINATE or lo >= hi:
            return False
    return True


def _union_volume(values: Sequence[int], left: int, right: int) -> int:
    result = 1
    for d in range(4):
        lo = min(values[left + d], values[right + d])
        hi = max(values[left + 4 + d], values[right + 4 + d])
        result *= hi - lo
    return result


def _volume(values: Sequence[int], at: int) -> int:
    result = 1
    for d in range(4):
        result *= values[at + 4 + d] - values[at + d]
    return result


def _penalty(values: Sequence[int], seed: int, entry: int) -> int:
    return _union_volume(values, seed, entry) - _volume(values, seed)


def expected_result(values: Sequence[int] | None, *, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    if type(input_is_null) is not bool or input_is_null or values is None:
        return INVALID_RESULT
    if not isinstance(values, (list, tuple)) or not 1 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH:
        return INVALID_RESULT
    if input_length is not None and (type(input_length) is not int or input_length != len(values)):
        return INVALID_RESULT
    if any(type(x) is not int or not -(2**63) <= x < 2**63 for x in values):
        return INVALID_RESULT
    fan = values[0]
    if not MIN_FAN <= fan <= MAX_FAN or len(values) != 1 + 8 * (fan + 1):
        return INVALID_RESULT
    count = fan + 1
    if any(not _valid_box(values, 1 + 8 * i) for i in range(count)):
        return INVALID_RESULT

    # The source scans forward pairs and replaces the seed pair only on >.
    seed_a, seed_b = 0, 1
    largest_union = _union_volume(values, 1, 1 + 8)
    for i in range(count):
        for j in range(i + 1, count):
            union = _union_volume(values, 1 + 8 * i, 1 + 8 * j)
            if union > largest_union:
                seed_a, seed_b = i, j
                largest_union = union

    group_a_size = group_b_size = 1
    mask = (1 << seed_a)
    seed_a_at, seed_b_at = 1 + 8 * seed_a, 1 + 8 * seed_b
    for i in range(count):
        if i == seed_a or i == seed_b:
            continue
        at = 1 + 8 * i
        if group_a_size < fan and group_b_size < fan:
            if _penalty(values, seed_a_at, at) < _penalty(values, seed_b_at, at):
                mask |= 1 << i
                group_a_size += 1
            else:
                group_b_size += 1
        elif group_a_size >= fan and group_b_size < fan:
            group_b_size += 1
        elif group_b_size >= fan and group_a_size < fan:
            mask |= 1 << i
            group_a_size += 1
        else:
            return INVALID_RESULT
    return mask


oracle = expected_result
