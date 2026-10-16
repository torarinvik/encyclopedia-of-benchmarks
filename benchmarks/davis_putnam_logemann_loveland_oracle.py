"""Oracle for a bounded CNF satisfiability contract."""
from __future__ import annotations

from itertools import product

MAX_VARIABLES = 5
MAX_CLAUSES = 10
MAX_CLAUSE_LENGTH = 5
MAX_INPUT_LENGTH = 2 + MAX_CLAUSES * (1 + MAX_CLAUSE_LENGTH)
INVALID = -1


def expected_result(values: list[int] | tuple[int, ...]) -> int:
    if (not isinstance(values, (list, tuple)) or not 2 <= len(values) <= MAX_INPUT_LENGTH
            or any(type(value) is not int for value in values)):
        return INVALID
    variable_count, clause_count = values[:2]
    if not 0 <= variable_count <= MAX_VARIABLES or not 0 <= clause_count <= MAX_CLAUSES:
        return INVALID
    clauses: list[tuple[int, ...]] = []
    position = 2
    for _ in range(clause_count):
        if position >= len(values):
            return INVALID
        clause_length = values[position]
        position += 1
        if not 0 <= clause_length <= MAX_CLAUSE_LENGTH or position + clause_length > len(values):
            return INVALID
        literals = tuple(values[position:position + clause_length])
        if any(literal == 0 or abs(literal) > variable_count for literal in literals):
            return INVALID
        clauses.append(literals)
        position += clause_length
    if position != len(values):
        return INVALID
    for assignment in product((False, True), repeat=variable_count):
        if all(any(assignment[abs(literal) - 1] == (literal > 0) for literal in clause)
               for clause in clauses):
            return 1
    return 0
