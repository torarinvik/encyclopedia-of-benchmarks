"""Independent clause-by-clause verifier for DOI330 k-OPT."""

from __future__ import annotations

import struct
from collections.abc import Sequence

MAX_VARS = 12
MAX_CLAUSES = 32
MAX_INPUT_LENGTH = 98
MAX_OUTPUT_BYTES = 104


def _sat_vector(assignment: list[bool], clauses: list[tuple[int, int, int]]) -> list[bool]:
    return [any(assignment[abs(lit) - 1] == (lit > 0) for lit in clause) for clause in clauses]


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    invalid, output_error = -1, -2
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or capacity is not None and (type(capacity) is not int or capacity < 0)
            or input_length is not None and (type(input_length) is not int
                                             or not 0 <= input_length <= MAX_INPUT_LENGTH)
            or input_is_null and values not in (None, [], ())
            or not input_is_null and values is not None and input_length is not None
            and input_length != len(values)):
        return invalid, b""
    if input_is_null or not isinstance(values, (list, tuple)):
        return invalid, b""
    if (not 2 <= len(values) <= MAX_INPUT_LENGTH
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return invalid, b""
    n, m = values[0], values[1]
    if not 3 <= n <= MAX_VARS or not 0 <= m <= MAX_CLAUSES or len(values) != 2 + 3 * m:
        return invalid, b""
    clauses: list[tuple[int, int, int]] = []
    for offset in range(2, len(values), 3):
        clause = tuple(values[offset:offset + 3])
        if (any(lit == 0 or abs(lit) > n for lit in clause)
                or len({abs(lit) for lit in clause}) != 3):
            return invalid, b""
        clauses.append(clause)
    pos = [0] * n
    neg = [0] * n
    for clause in clauses:
        for lit in clause:
            if lit > 0: pos[lit - 1] += 1
            else: neg[-lit - 1] += 1
    assignment = [pos[i] > neg[i] for i in range(n)]
    k = 1
    while True:
        current = _sat_vector(assignment, clauses)
        if all(current):
            status = 1
            break
        replacement = None
        for code in range(1 << n):
            candidate = [bool((code >> (n - 1 - i)) & 1) for i in range(n)]
            distance = sum(a != b for a, b in zip(assignment, candidate))
            if not 1 <= distance <= k:
                continue
            after = _sat_vector(candidate, clauses)
            if all(not before or after[j] for j, before in enumerate(current)) and any(
                    after[j] and not current[j] for j in range(m)):
                replacement = candidate
                break
        if replacement is not None:
            assignment = replacement
            continue
        if k == n:
            status = 0
            break
        k += 1
    result = [status] + [1 if value else -1 for value in assignment]
    payload = struct.pack("<" + "q" * len(result), *result)
    if output_is_null or capacity is not None and capacity < len(payload):
        return output_error, b""
    return len(payload), payload
