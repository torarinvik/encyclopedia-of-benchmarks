"""Explicit-state reachability reference, independent of BDD operations."""


def expected(values):
    if (not isinstance(values, (list, tuple)) or not 4 <= len(values) <= 133
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return -1
    n, m, initial_mask, invariant_mask = values[:4]
    if not 1 <= n <= 3 or not 0 <= m <= 1:
        return -1
    states = 1 << n
    allowed_mask = (1 << states) - 1
    inputs = 1 << m
    if (initial_mask < 0 or initial_mask & ~allowed_mask
            or invariant_mask < 0 or invariant_mask & ~allowed_mask
            or len(values) != 4 + states * inputs * states
            or any(bit not in (0, 1) for bit in values[4:])):
        return -1
    relation = values[4:]
    reached = initial_mask
    for _ in range(states + 1):
        enlarged = reached
        for state in range(states):
            if (reached >> state) & 1:
                for input_value in range(inputs):
                    row = (state * inputs + input_value) * states
                    for target in range(states):
                        if relation[row + target]:
                            enlarged |= 1 << target
        if enlarged == reached:
            break
        reached = enlarged
    else:
        return -1
    violation = int((reached & ~invariant_mask) != 0)
    return (reached << 1) | violation
