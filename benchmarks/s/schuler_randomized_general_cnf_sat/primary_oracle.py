"""Recursive reference for Schuler's supplied-tape general-CNF procedure."""

MAX_N = 6
MAX_M = 4
MAX_VALID_INPUT = 121
MAX_OUTPUT_BYTES = 48


def _parse(values):
    if values is None or not 2 <= len(values) <= MAX_VALID_INPUT + 1:
        return None
    if any(type(value) is not int for value in values):
        return None
    n, m = values[:2]
    if not 1 <= n <= MAX_N or not 1 <= m <= MAX_M:
        return None
    position = 2
    clauses = []
    for _ in range(m):
        if position >= len(values):
            return None
        size = values[position]
        position += 1
        if not 1 <= size <= n or position + size > len(values):
            return None
        clause = values[position:position + size]
        position += size
        seen = set()
        for literal in clause:
            variable = abs(literal)
            if literal == 0 or variable > n or variable in seen:
                return None
            seen.add(variable)
        clauses.append(clause)

    tapes = []
    for _ in range(n + 1):
        if position + 2 * n + 1 > len(values):
            return None
        permutation = values[position:position + n]
        position += n
        bits = values[position:position + n]
        position += n
        choice = values[position]
        position += 1
        if set(permutation) != set(range(1, n + 1)):
            return None
        if any(bit not in (0, 1) for bit in bits) or not 0 <= choice < m:
            return None
        tapes.append((permutation, bits, choice))
    if position != len(values):
        return None
    return n, m, clauses, tapes


def _short_limit(clause_count):
    # The paper defines log(m) as the least integer strictly greater than log2(m).
    return clause_count.bit_length() + 1


def _restrict(clauses, assignment):
    result = []
    for clause in clauses:
        remaining = []
        satisfied = False
        for literal in clause:
            variable = abs(literal)
            value = assignment.get(variable)
            if value is None:
                remaining.append(literal)
            elif (literal > 0) == bool(value):
                satisfied = True
                break
        if not satisfied:
            result.append(remaining)
    return result


def _ppz(clauses, fixed, n, tape):
    permutation, bits, _ = tape
    # PPZ follows the full permutation, including variables absent from G.
    # Variables fixed by an ancestor have already been removed from this call.
    order = [variable for variable in permutation if variable not in fixed]
    work = [clause.copy() for clause in clauses]
    local = {}
    unit_forces = 0
    random_guesses = 0
    for offset, variable in enumerate(order):
        positive_unit = any(len(clause) == 1 and clause[0] == variable for clause in work)
        negative_unit = any(len(clause) == 1 and clause[0] == -variable for clause in work)
        if positive_unit:
            value = 1
            unit_forces += 1
        elif negative_unit:
            value = 0
            unit_forces += 1
        else:
            value = bits[offset]
            random_guesses += 1
        local[variable] = value
        work = _restrict(work, {variable: value})
    if any(not clause for clause in work):
        return False, {}, unit_forces, random_guesses
    return True, local, unit_forces, random_guesses


def _encode(words):
    return b"".join(word.to_bytes(8, "little", signed=True) for word in words)


def evaluate(values):
    parsed = _parse(values)
    if parsed is None:
        return -1, b""
    n, _, initial, tapes = parsed
    stats = {"calls": 0, "units": 0, "guesses": 0, "max_depth": 0}

    def solve(clauses, fixed, depth):
        stats["calls"] += 1
        stats["max_depth"] = max(stats["max_depth"], depth)
        if not clauses:
            return True, fixed.copy()
        k = _short_limit(len(clauses))
        shortened = [clause[:k] for clause in clauses]
        success, local, units, guesses = _ppz(shortened, fixed, n, tapes[depth])
        stats["units"] += units
        stats["guesses"] += guesses
        if success:
            assignment = fixed.copy()
            assignment.update(local)
            for variable in range(1, n + 1):
                assignment.setdefault(variable, 0)
            return True, assignment

        candidates = [index for index, clause in enumerate(clauses) if len(clause) >= k]
        if not candidates:
            return False, {}
        choice = tapes[depth][2]
        if choice >= len(candidates):
            raise ValueError("clause choice is outside the eligible long-clause set")
        selected = clauses[candidates[choice]][:k]
        extended = fixed.copy()
        for literal in selected:
            extended[abs(literal)] = 0 if literal > 0 else 1
        residual = _restrict(clauses, extended)
        return solve(residual, extended, depth + 1)

    try:
        found, assignment = solve(initial, {}, 0)
    except ValueError:
        return -1, b""
    mask = sum((1 << (variable - 1)) for variable in range(1, n + 1)
               if assignment.get(variable, 0)) if found else 0
    words = [int(found), mask, stats["calls"], stats["units"],
             stats["guesses"], stats["max_depth"]]
    output = _encode(words)
    return len(output), output
