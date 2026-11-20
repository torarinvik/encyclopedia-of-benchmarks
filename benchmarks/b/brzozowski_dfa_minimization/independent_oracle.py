"""Independent reachable-state and table-filling DFA equivalence reference."""

from collections.abc import Sequence

from .primary_oracle import MAX_ALPHABET, MAX_PARSEABLE_INPUT_LENGTH, MAX_STATES


def expected(values: Sequence[int] | None) -> int:
    if values is None or not isinstance(values, (list, tuple)) or not 3 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH:
        return -1
    if any(type(value) is not int or not -(1 << 63) <= value < (1 << 63) for value in values):
        return -1
    n, start, accepting = values[:3]
    if not 1 <= n <= MAX_STATES or not 0 <= start < n or not 0 <= accepting < (1 << n):
        return -1
    if len(values) != 3 + MAX_ALPHABET * n:
        return -1
    transitions = []
    cursor = 3
    for _ in range(n):
        pair = (values[cursor], values[cursor + 1])
        if any(not 0 <= target < n for target in pair):
            return -1
        transitions.append(pair)
        cursor += 2

    reachable = {start}
    frontier = [start]
    while frontier:
        state = frontier.pop()
        for target in transitions[state]:
            if target not in reachable:
                reachable.add(target)
                frontier.append(target)
    ordered = sorted(reachable)
    distinguishable = [[False] * n for _ in range(n)]
    for i, a in enumerate(ordered):
        for b in ordered[i + 1:]:
            distinguishable[a][b] = bool((accepting >> a) & 1) != bool((accepting >> b) & 1)

    changed = True
    while changed:
        changed = False
        for i, a in enumerate(ordered):
            for b in ordered[i + 1:]:
                if distinguishable[a][b]:
                    continue
                if any(
                    transitions[a][symbol] != transitions[b][symbol]
                    and distinguishable[min(transitions[a][symbol], transitions[b][symbol])]
                                            [max(transitions[a][symbol], transitions[b][symbol])]
                    for symbol in range(MAX_ALPHABET)
                ):
                    distinguishable[a][b] = True
                    changed = True
    classes: list[list[int]] = []
    for state in ordered:
        for group in classes:
            representative = group[0]
            if not distinguishable[min(state, representative)][max(state, representative)]:
                group.append(state)
                break
        else:
            classes.append([state])
    return len(classes)
