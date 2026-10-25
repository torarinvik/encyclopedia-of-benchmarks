"""Independent repeated-scan oracle for bounded Bison nullable analysis."""

from __future__ import annotations

from collections.abc import Sequence

MAX_NONTERMINALS = 16
MAX_TERMINALS = 16
MAX_RULES = 32
MAX_RHS = 8
MAX_INPUT_LENGTH = 3 + MAX_RULES * (2 + MAX_RHS)
INVALID_RESULT = -1


def expected_result(values: Sequence[int] | None,
                    input_length: int | None = None) -> int:
    if (not isinstance(values, (list, tuple)) or len(values) < 5 or
            len(values) > MAX_INPUT_LENGTH or
            any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                for value in values)):
        return INVALID_RESULT
    actual_length = len(values) if input_length is None else input_length
    if type(actual_length) is not int or actual_length != len(values):
        return INVALID_RESULT

    nonterminal_count, terminal_count, rule_count = values[:3]
    if not 1 <= nonterminal_count <= MAX_NONTERMINALS:
        return INVALID_RESULT
    if not 0 <= terminal_count <= MAX_TERMINALS:
        return INVALID_RESULT
    if not 1 <= rule_count <= MAX_RULES:
        return INVALID_RESULT

    rules: list[tuple[int, tuple[int, ...]]] = []
    offset = 3
    for _ in range(rule_count):
        if offset + 2 > actual_length:
            return INVALID_RESULT
        lhs, rhs_count = values[offset:offset + 2]
        offset += 2
        if not 0 <= lhs < nonterminal_count or not 0 <= rhs_count <= MAX_RHS:
            return INVALID_RESULT
        if offset + rhs_count > actual_length:
            return INVALID_RESULT
        rhs = tuple(values[offset:offset + rhs_count])
        offset += rhs_count
        if any(symbol < 0 or symbol >= nonterminal_count + terminal_count
               for symbol in rhs):
            return INVALID_RESULT
        rules.append((lhs, rhs))
    if offset != actual_length:
        return INVALID_RESULT

    # This deliberately uses whole-grammar rescans, independently of the
    # source's queue plus reverse dependency-count implementation.
    nullable: set[int] = set()
    changed = True
    while changed:
        changed = False
        for lhs, rhs in rules:
            if lhs in nullable:
                continue
            if all(symbol < nonterminal_count and symbol in nullable for symbol in rhs):
                nullable.add(lhs)
                changed = True

    return sum(1 << symbol for symbol in nullable)
