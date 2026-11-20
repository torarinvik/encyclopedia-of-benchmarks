"""Independent reference using assignment-vector PPZ and iterative recursion."""

MAX_N = 6
MAX_M = 4


def _decode(values):
    if values is None or not 2 <= len(values) <= 122:
        return None
    if any(type(value) is not int for value in values):
        return None
    n, m = values[0], values[1]
    if n not in range(1, MAX_N + 1) or m not in range(1, MAX_M + 1):
        return None
    cursor = 2
    clauses = []
    for _ in range(m):
        if cursor >= len(values):
            return None
        count = values[cursor]
        cursor += 1
        if count < 1 or count > n or cursor + count > len(values):
            return None
        literals = list(values[cursor:cursor + count])
        cursor += count
        variables = [abs(literal) for literal in literals]
        if any(literal == 0 or variable > n for literal, variable in zip(literals, variables)):
            return None
        if len(set(variables)) != len(variables):
            return None
        clauses.append(literals)
    tapes = []
    for _ in range(n + 1):
        stop = cursor + 2 * n + 1
        if stop > len(values):
            return None
        permutation = tuple(values[cursor:cursor + n])
        bits = tuple(values[cursor + n:cursor + 2 * n])
        choice = values[cursor + 2 * n]
        cursor = stop
        if sorted(permutation) != list(range(1, n + 1)):
            return None
        if any(bit not in (0, 1) for bit in bits) or not 0 <= choice < m:
            return None
        tapes.append((permutation, bits, choice))
    if cursor != len(values):
        return None
    return n, m, clauses, tapes


def _prefix_size(m):
    return m.bit_length() + 1


def _restrict_formula(clauses, assignment):
    residual = []
    for clause in clauses:
        survivors = []
        has_true = False
        for literal in clause:
            value = assignment[abs(literal)]
            if value < 0:
                survivors.append(literal)
            elif (literal > 0) == (value == 1):
                has_true = True
                break
        if not has_true:
            residual.append(survivors)
    return residual


def _ppz_by_queries(prefix_formula, fixed, n, tape):
    permutation, bits, _ = tape
    # The source PPZ pass visits every variable in the supplied permutation;
    # only ancestor-fixed variables are skipped in this bounded profile.
    order = [variable for variable in permutation if fixed[variable] < 0]
    assigned = fixed[:]
    forces = 0
    guesses = 0
    for offset, variable in enumerate(order):
        positive = False
        negative = False
        for clause in prefix_formula:
            has_satisfied = False
            unknown = []
            for literal in clause:
                value = assigned[abs(literal)]
                if value < 0:
                    unknown.append(literal)
                elif (literal > 0) == (value == 1):
                    has_satisfied = True
                    break
            if not has_satisfied and len(unknown) == 1 and abs(unknown[0]) == variable:
                positive |= unknown[0] > 0
                negative |= unknown[0] < 0
        if positive:
            value = 1
            forces += 1
        elif negative:
            value = 0
            forces += 1
        else:
            value = bits[offset]
            guesses += 1
        assigned[variable] = value
    satisfied = all(any((literal > 0) == (assigned[abs(literal)] == 1)
                        for literal in clause) for clause in prefix_formula)
    return satisfied, assigned, forces, guesses


def _encode(words):
    return b"".join(int(word).to_bytes(8, "little", signed=True) for word in words)


def evaluate(values):
    decoded = _decode(values)
    if decoded is None:
        return -1, b""
    n, _, formula, tapes = decoded
    fixed = [-1] * (n + 1)
    calls = units = guesses = depth = 0
    found = False
    result_assignment = None
    while True:
        calls += 1
        depth = calls - 1
        if not formula:
            found = True
            result_assignment = fixed
            break
        k = _prefix_size(len(formula))
        prefix_formula = [clause[:k] for clause in formula]
        success, candidate_assignment, forced, guessed = _ppz_by_queries(
            prefix_formula, fixed, n, tapes[depth]
        )
        units += forced
        guesses += guessed
        if success:
            found = True
            result_assignment = candidate_assignment
            break
        eligible = [index for index, clause in enumerate(formula) if len(clause) >= k]
        if not eligible:
            break
        choice = tapes[depth][2]
        if choice >= len(eligible):
            return -1, b""
        selected = formula[eligible[choice]][:k]
        for literal in selected:
            fixed[abs(literal)] = 0 if literal > 0 else 1
        formula = _restrict_formula(formula, fixed)
    if found:
        mask = sum(1 << (variable - 1) for variable in range(1, n + 1)
                   if result_assignment[variable] == 1)
    else:
        mask = 0
    output = _encode([int(found), mask, calls, units, guesses, depth])
    return len(output), output
