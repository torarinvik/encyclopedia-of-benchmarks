"""Directly scan every previously inserted line for each arbitrary-x query."""

from __future__ import annotations

from collections.abc import Sequence

from .primary_oracle import (
    CHECKSUM_OFFSET,
    COEFFICIENT_LIMIT,
    INVALID_RESULT,
    MAX_OPERATIONS,
    MAX_PARSEABLE_INPUT_LENGTH,
    MAX_VALID_INPUT_LENGTH,
    QUERY_LIMIT,
)


def expected_result(values: Sequence[int] | None, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple))
            or len(values) < 2 or len(values) > MAX_PARSEABLE_INPUT_LENGTH
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return INVALID_RESULT
    if input_length is not None and (
            type(input_length) is not int or input_length != len(values)):
        return INVALID_RESULT
    objective_mode, operation_count = values[:2]
    if objective_mode not in (0, 1) or not 0 <= operation_count <= MAX_OPERATIONS:
        return INVALID_RESULT
    if len(values) != 2 + 3 * operation_count or len(values) > MAX_VALID_INPUT_LENGTH:
        return INVALID_RESULT

    objective = 1 if objective_mode == 1 else -1
    lines: list[tuple[int, int]] = []
    checksum = 0
    query_index = 0
    cursor = 2
    for _ in range(operation_count):
        opcode, first, second = values[cursor:cursor + 3]
        cursor += 3
        if opcode == 0:
            if (not -COEFFICIENT_LIMIT <= first <= COEFFICIENT_LIMIT
                    or not -COEFFICIENT_LIMIT <= second <= COEFFICIENT_LIMIT):
                return INVALID_RESULT
            lines.append((first, second))
        elif opcode == 1:
            if not lines or not -QUERY_LIMIT <= first <= QUERY_LIMIT or second != 0:
                return INVALID_RESULT
            candidates = [slope * first + intercept for slope, intercept in lines]
            optimum = (max(candidates) if objective_mode == 1 else min(candidates))
            checksum += (query_index + 1) * (optimum + CHECKSUM_OFFSET)
            query_index += 1
        else:
            return INVALID_RESULT
    return checksum
