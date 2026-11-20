"""Mutable-formula reference for the bounded CL bucket heuristic."""

from __future__ import annotations

import struct
from collections.abc import Sequence

MAX_VARS = 8
MAX_CLAUSES = 24
MAX_INPUT_LENGTH = 98
MAX_PARSEABLE_INPUT_LENGTH = 99
MAX_OUTPUT_BYTES = 352
WORKSPACE_BYTES = 16_384


def _decode(values: Sequence[int] | None) -> tuple[int, list[list[int]]] | None:
    if (not isinstance(values, (list, tuple)) or not 2 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return None
    n, m = values[0], values[1]
    if not 1 <= n <= MAX_VARS or not 0 <= m <= MAX_CLAUSES or len(values) != 2 + 4 * m:
        return None
    formula: list[list[int]] = []
    for clause_id in range(m):
        offset = 2 + 4 * clause_id
        size = values[offset]
        raw = list(values[offset + 1:offset + 4])
        if not 1 <= size <= 3 or any(raw[i] == 0 or abs(raw[i]) > n for i in range(size)):
            return None
        if any(abs(raw[i]) == abs(raw[j]) for i in range(size) for j in range(i)):
            return None
        if any(raw[i] != 0 for i in range(size, 3)):
            return None
        formula.append(raw[:size])
    return n, formula


def _apply(formula: list[list[int]], assigned: list[int], literal: int
           ) -> list[list[int]] | None:
    variable = abs(literal) - 1
    value = 1 if literal > 0 else -1
    if assigned[variable] and assigned[variable] != value:
        return None
    assigned[variable] = value
    result: list[list[int]] = []
    for clause in formula:
        if literal in clause:
            continue
        residual = [item for item in clause if item != -literal]
        if not residual:
            return None
        result.append(residual)
    return result


def _unit_propagate(formula: list[list[int]], assigned: list[int], trace: list[tuple[int, int, int, int]]
                    ) -> list[list[int]] | None:
    while True:
        unit = next((clause[0] for clause in formula if len(clause) == 1), None)
        if unit is None:
            return formula
        trace.append((unit, 1, -1, -1))
        formula = _apply(formula, assigned, unit)
        if formula is None:
            return None


def _degrees(n: int, formula: list[list[int]]) -> tuple[list[int], list[int]]:
    positive = [0] * n
    negative = [0] * n
    for clause in formula:
        for literal in clause:
            (positive if literal > 0 else negative)[abs(literal) - 1] += 1
    return positive, negative


def _bucket_literal(n: int, formula: list[list[int]], assigned: list[int],
                    bucket_i: int, bucket_j: int) -> int | None:
    positive, negative = _degrees(n, formula)
    candidates: list[int] = []
    for variable in range(n):
        if assigned[variable]:
            continue
        pos = min(10, positive[variable])
        neg = min(10, negative[variable])
        if (pos, neg) == (bucket_i, bucket_j):
            candidates.append(variable + 1)
        if (neg, pos) == (bucket_i, bucket_j):
            candidates.append(-(variable + 1))
    if not candidates:
        return None
    return min(candidates, key=lambda literal: (abs(literal), literal < 0))


def _rates(formula: list[list[int]], n: int) -> tuple[int, int, int]:
    size2 = sum(len(clause) == 2 for clause in formula)
    divisor = 2 * size2 if size2 else 1
    degree2_pos = [0] * n
    degree2_neg = [0] * n
    degree3_pos = [0] * n
    degree3_neg = [0] * n
    for clause in formula:
        if len(clause) == 2:
            positive, negative = degree2_pos, degree2_neg
        elif len(clause) == 3:
            positive, negative = degree3_pos, degree3_neg
        else:
            continue
        for literal in clause:
            (positive if literal > 0 else negative)[abs(literal) - 1] += 1
    s2 = 0
    s3 = 0
    for clause in formula:
        if len(clause) != 2:
            continue
        for literal in clause:
            opposite = -literal
            variable = abs(opposite) - 1
            s2 += degree2_pos[variable] if opposite > 0 else degree2_neg[variable]
            s3 += degree3_pos[variable] if opposite > 0 else degree3_neg[variable]
    return s2, s3, divisor


def _round(formula: list[list[int]], assigned: list[int], n: int, literal: int
           ) -> tuple[list[list[int]], list[int]] | None:
    next_assigned = assigned[:]
    residual = _apply([clause[:] for clause in formula], next_assigned, literal)
    if residual is None:
        return None
    residual = _unit_propagate(residual, next_assigned, [])
    if residual is None:
        return None
    return residual, next_assigned


def _choose_bucket(n: int, formula: list[list[int]], assigned: list[int]
                   ) -> tuple[int, int, int] | None:
    old2, old3, old_d = _rates(formula, n)
    best: tuple[int, int, int, int] | None = None
    for bucket_i in range(11):
        for bucket_j in range(11):
            literal = _bucket_literal(n, formula, assigned, bucket_i, bucket_j)
            if literal is None:
                continue
            outcome = _round(formula, assigned, n, literal)
            if outcome is None:
                continue
            new_formula, _ = outcome
            new2, new3, new_d = _rates(new_formula, n)
            numerator = new2 * old_d - old2 * new_d
            denominator = new3 * old_d - old3 * new_d
            if denominator == 0:
                continue
            if denominator < 0:
                numerator, denominator = -numerator, -denominator
            candidate = (numerator, denominator, bucket_i, bucket_j)
            if (best is None or numerator * best[1] > best[0] * denominator
                    or (numerator * best[1] == best[0] * denominator
                        and (bucket_i, bucket_j) < (best[2], best[3]))):
                best = candidate
    if best is None:
        return None
    return best[2], best[3], best[0]  # score numerator is not part of the decision output


def _trace(n: int, formula: list[list[int]]) -> tuple[int, list[int], list[tuple[int, int, int, int]]]:
    assigned = [0] * n
    trace: list[tuple[int, int, int, int]] = []
    formula = _unit_propagate(formula, assigned, trace)
    if formula is None:
        return 1, assigned, trace

    while any(value == 0 for value in assigned):
        selected = _choose_bucket(n, formula, assigned)
        if selected is None:
            return 2, assigned, trace
        bucket_i, bucket_j, _ = selected
        literal = _bucket_literal(n, formula, assigned, bucket_i, bucket_j)
        if literal is None:
            return 2, assigned, trace
        trace.append((literal, 0, bucket_i, bucket_j))
        formula = _apply(formula, assigned, literal)
        if formula is None:
            return 1, assigned, trace
        formula = _unit_propagate(formula, assigned, trace)
        if formula is None:
            return 1, assigned, trace
    return 0, assigned, trace


def _pack(status: int, assignment: list[int], trace: list[tuple[int, int, int, int]]) -> bytes:
    words = [status, len(assignment), sum(value != 0 for value in assignment), *assignment,
             len(trace)]
    for item in trace:
        words.extend(item)
    return struct.pack("<" + "q" * len(words), *words)


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or capacity is not None and (type(capacity) is not int or capacity < 0)
            or input_length is not None and (type(input_length) is not int
                                             or not 0 <= input_length <= MAX_PARSEABLE_INPUT_LENGTH)
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
    status, assignment, trace = _trace(*decoded)
    payload = _pack(status, assignment, trace)
    if output_is_null or capacity is not None and capacity < len(payload):
        return -2, b""
    return len(payload), payload


def expected_result(values: Sequence[int] | None) -> int:
    return expected_output(values)[0]
