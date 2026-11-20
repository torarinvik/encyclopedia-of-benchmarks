"""Direct-list matrix fold for the deque aggregation workload."""

from __future__ import annotations

from collections.abc import Sequence

from .primary_oracle import (
    IDENTITY,
    INVALID_RESULT,
    MAX_OPERATIONS,
    MAX_PARSEABLE_INPUT_LENGTH,
    MAX_VALID_INPUT_LENGTH,
    MODULUS,
)


def _multiply(left: tuple[int, int, int, int],
              right: tuple[int, int, int, int]) -> tuple[int, int, int, int]:
    a, b, c, d = left
    e, f, g, h = right
    return ((a * e + b * g) % MODULUS,
            (a * f + b * h) % MODULUS,
            (c * e + d * g) % MODULUS,
            (c * f + d * h) % MODULUS)


def _pack(matrix: tuple[int, int, int, int]) -> int:
    a, b, c, d = matrix
    return a + MODULUS * b + MODULUS**2 * c + MODULUS**3 * d


def expected_result(values: Sequence[int] | None, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple))
            or len(values) < 1 or len(values) > MAX_PARSEABLE_INPUT_LENGTH
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return INVALID_RESULT
    if input_length is not None and (
            type(input_length) is not int or input_length != len(values)):
        return INVALID_RESULT
    operation_count = values[0]
    if not 0 <= operation_count <= MAX_OPERATIONS:
        return INVALID_RESULT
    cursor = 1
    deque: list[tuple[int, int, int, int]] = []
    checksum = 0
    query_ordinal = 0
    for _ in range(operation_count):
        if cursor >= len(values):
            return INVALID_RESULT
        opcode = values[cursor]
        cursor += 1
        if opcode in (0, 1):
            if cursor + 4 > len(values):
                return INVALID_RESULT
            matrix = tuple(values[cursor:cursor + 4])
            cursor += 4
            if any(not 0 <= value < MODULUS for value in matrix):
                return INVALID_RESULT
            if opcode == 0:
                deque.insert(0, matrix)
            else:
                deque.append(matrix)
        elif opcode == 2:
            if not deque:
                return INVALID_RESULT
            del deque[0]
        elif opcode == 3:
            if not deque:
                return INVALID_RESULT
            deque.pop()
        elif opcode == 4:
            aggregate = IDENTITY
            for matrix in deque:
                aggregate = _multiply(aggregate, matrix)
            query_ordinal += 1
            checksum += query_ordinal * (_pack(aggregate) + 1)
        else:
            return INVALID_RESULT
    if cursor != len(values) or len(values) > MAX_VALID_INPUT_LENGTH:
        return INVALID_RESULT
    return checksum
