"""Primary oracle for the bounded clause-shortening Procedure S profile."""

from __future__ import annotations

from collections.abc import Sequence

MAX_VARS = 5
MAX_CLAUSES = 6
MAX_INPUT_LENGTH = 39
MAX_OUTPUT_BYTES = 48


def _parse(values: Sequence[int] | None) -> tuple[int, int, tuple[tuple[int, ...], ...]] | None:
    if (not isinstance(values, (list, tuple)) or not 3 <= len(values) <= MAX_INPUT_LENGTH
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return None
    variables, clause_count, k = values[:3]
    if not 1 <= variables <= MAX_VARS or not 0 <= clause_count <= MAX_CLAUSES or not 1 <= k <= variables:
        return None
    at = 3
    clauses: list[tuple[int, ...]] = []
    for _ in range(clause_count):
        if at >= len(values):
            return None
        count = values[at]
        at += 1
        if not 1 <= count <= variables or at + count > len(values):
            return None
        clause = tuple(values[at:at + count])
        at += count
        used: set[int] = set()
        for literal in clause:
            if literal == 0 or abs(literal) > variables or abs(literal) in used:
                return None
            used.add(abs(literal))
        clauses.append(clause)
    if at != len(values):
        return None
    return variables, k, tuple(clauses)


def _lex_model(clauses: tuple[tuple[int, ...], ...], variables: int,
               fixed_mask: int, fixed_values: int) -> int | None:
    for code in range(1 << variables):
        assignment = 0
        for variable in range(variables):
            if (code >> (variables - variable - 1)) & 1:
                assignment |= 1 << variable
        if (assignment ^ fixed_values) & fixed_mask:
            continue
        if all(any(((assignment >> (abs(lit) - 1)) & 1) == (lit > 0) for lit in clause)
               for clause in clauses):
            return assignment
    return None


def evaluate(values: Sequence[int] | None) -> tuple[int, bytes]:
    parsed = _parse(values)
    if parsed is None:
        return -1, b""
    variables, k, initial = parsed
    stats = [0, 0, 0, 0]  # calls, exact k-CNF checks, recursive branches, max depth

    def procedure_s(formula: tuple[tuple[int, ...], ...], fixed_mask: int,
                    fixed_values: int, depth: int) -> int | None:
        stats[0] += 1
        stats[3] = max(stats[3], depth)
        prefixes = tuple(clause[:k] for clause in formula)
        stats[1] += 1
        model = _lex_model(prefixes, variables, fixed_mask, fixed_values)
        if model is not None:
            return model
        for index, prefix in enumerate(prefixes):
            if not prefix:
                continue
            stats[2] += 1
            next_mask, next_values = fixed_mask, fixed_values
            for literal in prefix:
                bit = 1 << (abs(literal) - 1)
                value = bit if literal < 0 else 0
                next_mask |= bit
                next_values = (next_values & ~bit) | value
            newly_fixed = next_mask & ~fixed_mask
            child_clauses: list[tuple[int, ...]] = []
            for clause_index, clause in enumerate(formula):
                source = prefixes[clause_index] if clause_index < index else clause
                kept: list[int] = []
                satisfied = False
                for literal in source:
                    bit = 1 << (abs(literal) - 1)
                    if newly_fixed & bit:
                        truth = bool(next_values & bit)
                        if (literal > 0 and truth) or (literal < 0 and not truth):
                            satisfied = True
                            break
                    else:
                        kept.append(literal)
                if not satisfied:
                    child_clauses.append(tuple(kept))
            result = procedure_s(tuple(child_clauses), next_mask, next_values, depth + 1)
            if result is not None:
                return result
        return None

    model = procedure_s(initial, 0, 0, 0)
    words = [int(model is not None), model or 0, *stats]
    raw = b"".join(word.to_bytes(8, "little", signed=True) for word in words)
    return len(raw), raw


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
        return -1, b""
    if input_is_null or values is None:
        return -1, b""
    result, raw = evaluate(values)
    if result < 0:
        return result, raw
    if output_is_null or capacity is not None and capacity < len(raw):
        return -2, b""
    return result, raw
