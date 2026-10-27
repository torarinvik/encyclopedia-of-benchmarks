"""Occurrence-count oracle for the DOI330 majority-vote profile."""

from __future__ import annotations

import struct
from collections.abc import Sequence

MAX_VARS = 12
MAX_CLAUSES = 32
MAX_INPUT_LENGTH = 98
MAX_OUTPUT_BYTES = 96
INVALID_RESULT = -1
OUTPUT_ERROR = -2


def _decode(values: Sequence[int] | None) -> tuple[int, list[tuple[int, int, int]]] | None:
    if (not isinstance(values, (list, tuple)) or not 2 <= len(values) <= MAX_INPUT_LENGTH
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return None
    n, m = values[:2]
    if not 3 <= n <= MAX_VARS or not 0 <= m <= MAX_CLAUSES or len(values) != 2 + 3 * m:
        return None
    clauses: list[tuple[int, int, int]] = []
    for offset in range(2, len(values), 3):
        clause = tuple(values[offset:offset + 3])
        if (any(literal == 0 or abs(literal) > n for literal in clause)
                or len({abs(literal) for literal in clause}) != 3):
            return None
        clauses.append(clause)
    return n, clauses


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
        return INVALID_RESULT, b""
    if input_is_null or values is None:
        return INVALID_RESULT, b""
    decoded = _decode(values)
    if decoded is None:
        return INVALID_RESULT, b""
    n, clauses = decoded
    positive = [0] * n
    negative = [0] * n
    for clause in clauses:
        for literal in clause:
            variable = abs(literal) - 1
            if literal > 0:
                positive[variable] += 1
            else:
                negative[variable] += 1
    assignment = [1 if positive[v] > negative[v] else -1 for v in range(n)]
    payload = struct.pack("<" + "q" * n, *assignment)
    if output_is_null or capacity is not None and capacity < len(payload):
        return OUTPUT_ERROR, b""
    return len(payload), payload
