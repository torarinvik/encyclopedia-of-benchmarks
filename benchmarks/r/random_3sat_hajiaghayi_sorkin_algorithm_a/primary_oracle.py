"""Mutable-residual reference for Hajiaghayi-Sorkin Algorithm A."""

from __future__ import annotations

import struct
from collections.abc import Sequence

MAX_VARS = 12
MAX_CLAUSES = 32
MAX_INPUT_LENGTH = 98
MAX_OUTPUT_BYTES = 104
WORKSPACE_BYTES = 4096


def _decode(values: Sequence[int] | None) -> tuple[int, list[list[int]]] | None:
    if (not isinstance(values, (list, tuple)) or not 2 <= len(values) <= MAX_INPUT_LENGTH
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return None
    n, m = values[0], values[1]
    if not 3 <= n <= MAX_VARS or not 0 <= m <= MAX_CLAUSES or len(values) != 2 + 3 * m:
        return None
    clauses: list[list[int]] = []
    for offset in range(2, len(values), 3):
        clause = list(values[offset:offset + 3])
        if any(literal == 0 or abs(literal) > n for literal in clause):
            return None
        if len({abs(literal) for literal in clause}) != 3:
            return None
        clauses.append(clause)
    return n, clauses


def _apply(residual: list[list[int]], assigned: list[int], literal: int
           ) -> list[list[int]] | None:
    variable = abs(literal) - 1
    assigned[variable] = 1 if literal > 0 else -1
    updated: list[list[int]] = []
    for clause in residual:
        if literal in clause:
            continue
        remainder = [value for value in clause if value != -literal]
        if not remainder:
            return None
        updated.append(remainder)
    return updated


def _choose_free_literal(n: int, residual: list[list[int]],
                         assigned: list[int]) -> int:
    degrees = [[0, 0] for _ in range(n)]  # positive i, negative j
    for clause in residual:
        for literal in clause:
            variable = abs(literal) - 1
            degrees[variable][int(literal < 0)] += 1

    pure = next((v for v in range(n) if assigned[v] == 0
                 and (degrees[v][0] == 0 or degrees[v][1] == 0)), None)
    if pure is not None:
        variable = pure
    else:
        score = max((abs(positive - negative), positive + negative)
                    for v, (positive, negative) in enumerate(degrees)
                    if assigned[v] == 0)
        variable = next(v for v, (positive, negative) in enumerate(degrees)
                        if assigned[v] == 0
                        and (abs(positive - negative), positive + negative) == score)

    positive, negative = degrees[variable]
    # Algorithm A prints: set v True if i < j and False otherwise.
    return variable + 1 if positive < negative else -(variable + 1)


def _trace(n: int, clauses: list[list[int]]) -> tuple[int, list[int]]:
    residual = [clause[:] for clause in clauses]
    assigned = [0] * n
    assigned_count = 0
    failed = False

    while assigned_count < n and not failed:
        literal = _choose_free_literal(n, residual, assigned)
        variable = abs(literal) - 1
        if assigned[variable] == 0:
            assigned_count += 1
        updated = _apply(residual, assigned, literal)
        if updated is None:
            failed = True
            break
        residual = updated

        while True:
            unit = next((clause[0] for clause in residual if len(clause) == 1), None)
            if unit is None:
                break
            variable = abs(unit) - 1
            if assigned[variable] == 0:
                assigned_count += 1
            updated = _apply(residual, assigned, unit)
            if updated is None:
                failed = True
                break
            residual = updated

    return (0 if failed else 1), assigned


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or capacity is not None and (type(capacity) is not int or capacity < 0)
            or input_length is not None and (type(input_length) is not int
                                             or not 0 <= input_length <= MAX_INPUT_LENGTH)
            or input_is_null and values not in (None, [], ())
            or not input_is_null and values is not None
            and not isinstance(values, (list, tuple))
            or not input_is_null and values is not None and input_length is not None
            and input_length != len(values)):
        return -1, b""
    if input_is_null or values is None:
        return -1, b""
    decoded = _decode(values)
    if decoded is None:
        return -1, b""
    verdict, assignment = _trace(*decoded)
    payload = struct.pack("<" + "q" * (len(assignment) + 1), verdict, *assignment)
    if output_is_null or capacity is not None and capacity < len(payload):
        return -2, b""
    return len(payload), payload


def expected_result(values: Sequence[int] | None) -> int:
    return expected_output(values)[0]
