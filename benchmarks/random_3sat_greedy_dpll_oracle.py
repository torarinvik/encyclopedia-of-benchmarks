"""Mutable-clause oracle for the bounded DOI423 no-backtrack Greedy trace."""

from __future__ import annotations

import struct
from collections.abc import Sequence

MAX_VARS = 12
MAX_CLAUSES = 32
MAX_INPUT_LENGTH = 98
MAX_OUTPUT_BYTES = 104
INVALID_RESULT = -1
OUTPUT_ERROR = -2


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


def _greedy_trace(n: int, clauses: list[list[int]]) -> tuple[int, list[int]]:
    residual = [clause[:] for clause in clauses]
    assigned = [0] * n
    failed = False
    success = False
    for _ in range(n):
        if failed:
            break
        if not residual:
            success = True
            break
        unit = next((clause[0] for clause in residual if len(clause) == 1), None)
        if unit is None:
            counts = [[0, 0] for _ in range(n)]
            for clause in residual:
                for literal in clause:
                    counts[abs(literal) - 1][literal < 0] += 1
            # max() is made explicit to keep variable/sign tie order obvious.
            choice = (0, 0)
            best_count = -1
            for variable in range(n):
                for negative in (False, True):
                    count = counts[variable][negative]
                    if count > best_count:
                        best_count = count
                        choice = (variable + 1) * (1 if not negative else -1), count
            chosen = choice[0]
        else:
            chosen = unit
        if chosen == 0:
            failed = True
            break
        variable = abs(chosen) - 1
        assigned[variable] = 1 if chosen > 0 else -1
        updated: list[list[int]] = []
        for clause in residual:
            if chosen in clause:
                continue
            remainder = [literal for literal in clause if literal != -chosen]
            if not remainder:
                failed = True
                break
            updated.append(remainder)
        residual = updated
    if not failed:
        success = not residual
    if success:
        assigned = [value if value else -1 for value in assigned]
    return (1 if success else 0), assigned


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
    verdict, assignment = _greedy_trace(*decoded)
    payload = struct.pack("<" + "q" * (len(assignment) + 1), verdict, *assignment)
    if output_is_null or capacity is not None and capacity < len(payload):
        return OUTPUT_ERROR, b""
    return len(payload), payload
