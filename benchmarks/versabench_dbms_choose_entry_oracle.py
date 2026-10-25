"""Independent oracle for the bounded DIS R-tree chooseEntry operation."""
from __future__ import annotations

from collections.abc import Sequence

MIN_CHILDREN = 1
MAX_CHILDREN = 8
MIN_COORDINATE = -8
MAX_COORDINATE = 8
MAX_INPUT_LENGTH = 1 + 8 * MAX_CHILDREN + 8
MAX_PARSEABLE_INPUT_LENGTH = MAX_INPUT_LENGTH + 1
INVALID_RESULT = -1


def _read_box(values: Sequence[int], start: int) -> tuple[tuple[int, ...], tuple[int, ...]] | None:
    lower = tuple(values[start : start + 4])
    upper = tuple(values[start + 4 : start + 8])
    if any(not MIN_COORDINATE <= x <= MAX_COORDINATE for x in lower + upper):
        return None
    if any(lo >= hi for lo, hi in zip(lower, upper)):
        return None
    return lower, upper


def _volume(box: tuple[tuple[int, ...], tuple[int, ...]]) -> int:
    lower, upper = box
    result = 1
    for lo, hi in zip(lower, upper):
        result *= hi - lo
    return result


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
    count = values[0]
    if not MIN_CHILDREN <= count <= MAX_CHILDREN or len(values) != 1 + 8 * count + 8:
        return INVALID_RESULT
    boxes = []
    cursor = 1
    for _ in range(count):
        box = _read_box(values, cursor)
        if box is None:
            return INVALID_RESULT
        boxes.append(box)
        cursor += 8
    incoming = _read_box(values, cursor)
    if incoming is None:
        return INVALID_RESULT

    incoming_lo, incoming_hi = incoming
    best_index = 0
    first_lo, first_hi = boxes[0]
    best_volume = _volume(boxes[0])
    best_penalty = _volume((tuple(min(a, b) for a, b in zip(first_lo, incoming_lo)),
                            tuple(max(a, b) for a, b in zip(first_hi, incoming_hi)))) - best_volume
    for index in range(1, count):
        lower, upper = boxes[index]
        penalty = _volume((tuple(min(a, b) for a, b in zip(lower, incoming_lo)),
                           tuple(max(a, b) for a, b in zip(upper, incoming_hi)))) - _volume(boxes[index])
        # The C source replaces the current choice only for a strictly smaller penalty.
        if penalty < best_penalty:
            best_index = index
            best_penalty = penalty
    return best_index


oracle = expected_result
