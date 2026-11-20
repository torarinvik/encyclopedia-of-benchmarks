"""Exhaustive-subset reference for minimum half-open interval cover."""

from __future__ import annotations

from collections.abc import Sequence

INVALID_RESULT = -2
IMPOSSIBLE_RESULT = -1
INTERVAL_LIMIT = 16
COORDINATE_LIMIT = 32
FRAME_LIMIT = 3 + 2 * INTERVAL_LIMIT + 1


def expected_result(values: Sequence[int] | None, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple))
            or len(values) < 3 or len(values) > FRAME_LIMIT
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return INVALID_RESULT
    if input_length is not None and (
            type(input_length) is not int or input_length != len(values)):
        return INVALID_RESULT

    target_start, target_end, amount = values[0], values[1], values[2]
    if not 0 <= target_start <= target_end <= COORDINATE_LIMIT:
        return INVALID_RESULT
    if not 0 <= amount <= INTERVAL_LIMIT or len(values) != 3 + 2 * amount:
        return INVALID_RESULT
    ranges: list[tuple[int, int]] = []
    for item in range(amount):
        begin = values[3 + 2 * item]
        finish = values[4 + 2 * item]
        if begin < 0 or begin >= finish or finish > COORDINATE_LIMIT:
            return INVALID_RESULT
        ranges.append((begin, finish))

    if target_start == target_end:
        return 0
    best = amount + 1
    for chosen in range(1 << amount):
        count = chosen.bit_count()
        if count >= best:
            continue
        covered = True
        for cell in range(target_start, target_end):
            if not any((chosen & (1 << index))
                       and start <= cell and cell + 1 <= end
                       for index, (start, end) in enumerate(ranges)):
                covered = False
                break
        if covered:
            best = count
    return best if best <= amount else IMPOSSIBLE_RESULT
