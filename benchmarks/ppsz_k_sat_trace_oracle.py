"""Primary bit-mask oracle for a deterministic supplied-randomness PPSZ trace."""

from __future__ import annotations

from collections.abc import Sequence

MAX_N = 8
MAX_CLAUSES = 12
MAX_INPUT = 54
MAX_OUTPUT = 72


def _parse(values, input_is_null, input_length):
    if (input_is_null or not isinstance(values, (list, tuple)) or len(values) < 2
            or len(values) > MAX_INPUT
            or input_length is not None and (type(input_length) is not int or input_length != len(values))
            or any(type(x) is not int or not -(1 << 63) <= x < (1 << 63) for x in values)):
        return None
    n, m = values[:2]
    if not 3 <= n <= MAX_N or not 0 <= m <= MAX_CLAUSES or len(values) != 2 + 3 * m + 2 * n:
        return None
    clauses = []
    for i in range(m):
        clause = tuple(values[2 + 3 * i:5 + 3 * i])
        if (any(lit == 0 or abs(lit) > n for lit in clause)
                or len({abs(lit) for lit in clause}) != 3):
            return None
        clauses.append(clause)
    start = 2 + 3 * m
    permutation = tuple(values[start:start + n])
    beta = tuple(values[start + n:start + 2 * n])
    if sorted(permutation) != list(range(n)) or any(bit not in (0, 1) for bit in beta):
        return None
    return n, tuple(clauses), permutation, beta


def _completed_mask(mask: int, assignment: list[int]) -> int:
    for variable, value in enumerate(assignment):
        if value == 0:
            mask &= ~(1 << variable)
        elif value == 1:
            mask |= 1 << variable
    return mask


def _literal_true(literal: int, mask: int) -> bool:
    bit = (mask >> (abs(literal) - 1)) & 1
    return bit == 1 if literal > 0 else bit == 0


def _satisfies(clauses, mask: int) -> bool:
    return all(any(_literal_true(literal, mask) for literal in clause) for clause in clauses)


def _formula_satisfiable(n: int, clauses, assignment: list[int]) -> bool:
    return any(_satisfies(clauses, _completed_mask(mask, assignment)) for mask in range(1 << n))


def _implied(n: int, clauses, assignment: list[int]) -> tuple[int, int] | None:
    if not _formula_satisfiable(n, clauses, assignment):
        return None
    threshold = 0
    while (1 << (threshold + 1)) <= n:
        threshold += 1
    implied_by_variable = [-1] * n
    for subset in range(1, 1 << len(clauses)):
        if subset.bit_count() > threshold:
            continue
        seen_zero = [False] * n
        seen_one = [False] * n
        subset_clauses = [clause for i, clause in enumerate(clauses) if subset & (1 << i)]
        for mask in range(1 << n):
            full = _completed_mask(mask, assignment)
            if _satisfies(subset_clauses, full):
                for variable in range(n):
                    if assignment[variable] == -1:
                        if (full >> variable) & 1:
                            seen_one[variable] = True
                        else:
                            seen_zero[variable] = True
        for variable in range(n):
            if assignment[variable] == -1 and seen_zero[variable] != seen_one[variable]:
                if implied_by_variable[variable] == -1:
                    implied_by_variable[variable] = 1 if seen_one[variable] else 0
    for variable, value in enumerate(implied_by_variable):
        if value >= 0:
            return variable, value
    return None


def _solve(parsed):
    n, clauses, permutation, beta = parsed
    assignment = [-1] * n
    for variable in permutation:
        while True:
            force = _implied(n, clauses, assignment)
            if force is None:
                break
            forced_variable, value = force
            assignment[forced_variable] = value
        if assignment[variable] == -1:
            assignment[variable] = beta[variable]
    sat = int(_satisfies(clauses, sum(value << i for i, value in enumerate(assignment))))
    return [sat, *assignment]


def expected_output(values: Sequence[int] | None, output_capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if type(output_is_null) is not bool or type(input_is_null) is not bool:
        return -1, b""
    parsed = _parse(values, input_is_null, input_length)
    if parsed is None:
        return -1, b""
    result = _solve(parsed)
    payload = b"".join(value.to_bytes(8, "little", signed=True) for value in result)
    if output_capacity is not None and (type(output_capacity) is not int or output_capacity < 0):
        return -1, b""
    if output_is_null or output_capacity is not None and output_capacity < len(payload):
        return -2, b""
    return len(payload), payload
