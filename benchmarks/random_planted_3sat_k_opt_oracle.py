"""Satisfied-clause-set oracle for the bounded DOI330 k-OPT profile."""

from __future__ import annotations

import struct
from collections.abc import Sequence

MAX_VARS = 12
MAX_CLAUSES = 32
MAX_INPUT_LENGTH = 98
MAX_OUTPUT_BYTES = 104
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


def _satisfied_mask(assignment: list[bool], clauses: list[tuple[int, int, int]]) -> int:
    mask = 0
    for index, clause in enumerate(clauses):
        if any(assignment[abs(lit) - 1] == (lit > 0) for lit in clause):
            mask |= 1 << index
    return mask


def _majority(n: int, clauses: list[tuple[int, int, int]]) -> list[bool]:
    pos = [0] * n
    neg = [0] * n
    for clause in clauses:
        for lit in clause:
            (pos if lit > 0 else neg)[abs(lit) - 1] += 1
    return [pos[i] > neg[i] for i in range(n)]


def _k_opt(n: int, clauses: list[tuple[int, int, int]]) -> tuple[int, list[int]]:
    assignment = _majority(n, clauses)
    full = (1 << len(clauses)) - 1
    k = 1
    while True:
        current_mask = _satisfied_mask(assignment, clauses)
        if current_mask == full:
            return 1, [1 if value else -1 for value in assignment]
        move: list[bool] | None = None
        # Integer code order is lexicographic assignment order with false < true
        # and variable 1 as the most significant bit.
        for code in range(1 << n):
            candidate = [bool((code >> (n - 1 - i)) & 1) for i in range(n)]
            distance = sum(a != b for a, b in zip(assignment, candidate))
            if not 1 <= distance <= k:
                continue
            candidate_mask = _satisfied_mask(candidate, clauses)
            if candidate_mask != current_mask and candidate_mask & current_mask == current_mask:
                move = candidate
                break
        if move is not None:
            assignment = move
            continue
        if k == n:
            return 0, [1 if value else -1 for value in assignment]
        k += 1


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
    status, assignment = _k_opt(*decoded)
    payload = struct.pack("<" + "q" * (len(assignment) + 1), status, *assignment)
    if output_is_null or capacity is not None and capacity < len(payload):
        return OUTPUT_ERROR, b""
    return len(payload), payload
