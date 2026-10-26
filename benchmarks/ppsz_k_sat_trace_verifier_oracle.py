"""Independent recursive-assignment verifier oracle for the PPSZ trace profile."""

from __future__ import annotations

from collections.abc import Sequence
MAX_N = 8
MAX_CLAUSES = 12
MAX_INPUT = 54


def _models(n, clauses, assignment, selected=None):
    chosen = clauses if selected is None else selected
    unassigned = [i for i, value in enumerate(assignment) if value < 0]
    found = []
    trial = assignment[:]

    def visit(depth):
        if depth == len(unassigned):
            if all(any((trial[abs(lit) - 1] == 1) == (lit > 0) for lit in clause) for clause in chosen):
                found.append(tuple(trial))
            return
        variable = unassigned[depth]
        for bit in (0, 1):
            trial[variable] = bit
            visit(depth + 1)
        trial[variable] = -1

    visit(0)
    return found


def _force(n, clauses, assignment):
    if not _models(n, clauses, assignment):
        return None
    t = n.bit_length() - 1
    for variable in range(n):
        if assignment[variable] >= 0:
            continue
        for subset in range(1, 1 << len(clauses)):
            if subset.bit_count() > t:
                continue
            selected = [clause for i, clause in enumerate(clauses) if subset & (1 << i)]
            models = _models(n, selected, assignment)
            if models:
                values_seen = {model[variable] for model in models}
                if len(values_seen) == 1:
                    return variable, values_seen.pop()
    return None


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
        if any(lit == 0 or abs(lit) > n for lit in clause) or len({abs(lit) for lit in clause}) != 3:
            return None
        clauses.append(clause)
    start = 2 + 3 * m
    permutation = tuple(values[start:start + n])
    beta = tuple(values[start + n:start + 2 * n])
    if sorted(permutation) != list(range(n)) or any(bit not in (0, 1) for bit in beta):
        return None
    return n, tuple(clauses), permutation, beta


def _solve(parsed):
    n, clauses, permutation, beta = parsed
    assignment = [-1] * n
    for variable in permutation:
        while True:
            forced = _force(n, clauses, assignment)
            if forced is None:
                break
            assignment[forced[0]] = forced[1]
        if assignment[variable] < 0:
            assignment[variable] = beta[variable]
    sat = int(bool(_models(n, clauses, assignment)))
    return [sat, *assignment]


def expected_output(values: Sequence[int] | None, output_capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if type(output_is_null) is not bool or type(input_is_null) is not bool:
        return -1, b""
    parsed = _parse(values, input_is_null, input_length)
    if parsed is None:
        return -1, b""
    payload = b"".join(value.to_bytes(8, "little", signed=True) for value in _solve(parsed))
    if output_capacity is not None and (type(output_capacity) is not int or output_capacity < 0):
        return -1, b""
    if output_is_null or output_capacity is not None and output_capacity < len(payload):
        return -2, b""
    return len(payload), payload
