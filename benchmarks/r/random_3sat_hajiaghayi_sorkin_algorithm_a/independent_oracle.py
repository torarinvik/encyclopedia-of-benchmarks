"""Rebuilt-residual verifier for Hajiaghayi-Sorkin Algorithm A."""

from __future__ import annotations

import struct
from collections.abc import Sequence

MAX_VARS = 12
MAX_CLAUSES = 32
MAX_INPUT_LENGTH = 98


def _parse(values: Sequence[int] | None) -> tuple[int, tuple[tuple[int, ...], ...]] | None:
    if (not isinstance(values, (list, tuple)) or len(values) < 2
            or len(values) > MAX_INPUT_LENGTH
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return None
    n, m = values[0], values[1]
    if n < 3 or n > MAX_VARS or m < 0 or m > MAX_CLAUSES or len(values) != 2 + 3 * m:
        return None
    original: list[tuple[int, ...]] = []
    at = 2
    while at < len(values):
        clause = (values[at], values[at + 1], values[at + 2])
        if any(literal == 0 or abs(literal) > n for literal in clause):
            return None
        if len({abs(literal) for literal in clause}) != 3:
            return None
        original.append(clause)
        at += 3
    return n, tuple(original)


def _residual(original: tuple[tuple[int, ...], ...], assignment: list[int]
              ) -> list[list[int]] | None:
    clauses: list[list[int]] = []
    for original_clause in original:
        remaining: list[int] = []
        satisfied = False
        for literal in original_clause:
            state = assignment[abs(literal) - 1]
            if state == 0:
                remaining.append(literal)
            elif (literal > 0 and state == 1) or (literal < 0 and state == -1):
                satisfied = True
                break
        if satisfied:
            continue
        if not remaining:
            return None
        clauses.append(remaining)
    return clauses


def _select(n: int, clauses: list[list[int]], assignment: list[int]) -> int:
    positive = [0] * n
    negative = [0] * n
    for clause in clauses:
        for literal in clause:
            variable = abs(literal) - 1
            if literal > 0:
                positive[variable] += 1
            else:
                negative[variable] += 1

    for variable in range(n):
        if assignment[variable] == 0 and (positive[variable] == 0 or negative[variable] == 0):
            return variable + 1 if positive[variable] < negative[variable] else -(variable + 1)

    best_discrepancy = -1
    best_total = -1
    selected = -1
    for variable in range(n):
        if assignment[variable] != 0:
            continue
        discrepancy = abs(positive[variable] - negative[variable])
        total = positive[variable] + negative[variable]
        if discrepancy > best_discrepancy or (discrepancy == best_discrepancy and total > best_total):
            best_discrepancy, best_total, selected = discrepancy, total, variable
    return selected + 1 if positive[selected] < negative[selected] else -(selected + 1)


def _trace(n: int, original: tuple[tuple[int, ...], ...]) -> tuple[int, list[int]]:
    assignment = [0] * n
    assigned_count = 0
    failed = False
    while assigned_count < n and not failed:
        current = _residual(original, assignment)
        if current is None:
            failed = True
            break
        free_literal = _select(n, current, assignment)
        assignment[abs(free_literal) - 1] = 1 if free_literal > 0 else -1
        assigned_count += 1

        while True:
            current = _residual(original, assignment)
            if current is None:
                failed = True
                break
            unit_clause = next((clause for clause in current if len(clause) == 1), None)
            if unit_clause is None:
                break
            literal = unit_clause[0]
            assignment[abs(literal) - 1] = 1 if literal > 0 else -1
            assigned_count += 1

    return (0 if failed else 1), assignment


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
    parsed = _parse(values)
    if parsed is None:
        return -1, b""
    verdict, assignment = _trace(*parsed)
    payload = struct.pack("<" + "q" * (len(assignment) + 1), verdict, *assignment)
    if output_is_null or capacity is not None and capacity < len(payload):
        return -2, b""
    return len(payload), payload


def expected_result(values: Sequence[int] | None) -> int:
    return expected_output(values)[0]
