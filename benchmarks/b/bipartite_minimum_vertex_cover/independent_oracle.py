"""Exhaustive vertex-subset reference for canonical minimum-cover masks."""

from __future__ import annotations

from collections.abc import Sequence

MAX_SIDE = 8
MAX_VERTICES = 2 * MAX_SIDE
MAX_PARSEABLE_INPUT_LENGTH = MAX_SIDE + 3
INVALID_RESULT = -1


def expected_result(values: Sequence[int] | None, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    if (input_is_null or not isinstance(values, (list, tuple))
            or not 2 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
            or (input_length is not None
                and (type(input_length) is not int or input_length != len(values)
                     or not 0 <= input_length <= MAX_PARSEABLE_INPUT_LENGTH))
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return INVALID_RESULT
    left_count, right_count = values[0], values[1]
    if (not 0 <= left_count <= MAX_SIDE or not 0 <= right_count <= MAX_SIDE
            or len(values) != left_count + 2):
        return INVALID_RESULT
    right_domain = (1 << right_count) - 1
    rows = tuple(values[2:])
    if any(row < 0 or row & ~right_domain for row in rows):
        return INVALID_RESULT

    vertex_count = left_count + right_count
    best_size = vertex_count + 1
    best_mask = 0
    best_vector: tuple[int, ...] | None = None
    for mask in range(1 << vertex_count):
        size = mask.bit_count()
        if size > best_size:
            continue
        covers_all = True
        for left, row in enumerate(rows):
            if mask & (1 << left):
                continue
            for right in range(right_count):
                if (row & (1 << right)
                        and not mask & (1 << (left_count + right))):
                    covers_all = False
                    break
            if not covers_all:
                break
        if not covers_all:
            continue
        vector = tuple((mask >> vertex) & 1 for vertex in range(vertex_count))
        if size < best_size or best_vector is None or vector < best_vector:
            best_size = size
            best_mask = mask
            best_vector = vector
    return best_mask
