"""Suffix-automaton longest-common-substring length oracle."""

from collections.abc import Sequence


def evaluate(values: Sequence[int] | None) -> int:
    if values is None or not isinstance(values, (list, tuple)) or not 2 <= len(values) <= 515:
        return -1
    if any(type(x) is not int for x in values):
        return -1
    n = values[0]
    if not 0 <= n <= 256 or len(values) < n+2:
        return -1
    m = values[n+1]
    if not 0 <= m <= 256 or len(values) != 2+n+m or any(not 32 <= x <= 126 for x in values[1:n+1]) or any(not 32 <= x <= 126 for x in values[n+2:]):
        return -1
    transitions = [{}]; links = [-1]; lengths = [0]; last = 0
    for symbol in values[1:n+1]:
        current = len(links)
        transitions.append({}); links.append(0); lengths.append(lengths[last]+1)
        p = last
        while p >= 0 and symbol not in transitions[p]:
            transitions[p][symbol] = current
            p = links[p]
        if p >= 0:
            q = transitions[p][symbol]
            if lengths[p]+1 == lengths[q]:
                links[current] = q
            else:
                clone = len(links)
                transitions.append(transitions[q].copy()); links.append(links[q]); lengths.append(lengths[p]+1)
                while p >= 0 and transitions[p].get(symbol) == q:
                    transitions[p][symbol] = clone
                    p = links[p]
                links[q] = links[current] = clone
        last = current
    state = match = best = 0
    for symbol in values[n+2:]:
        while state and symbol not in transitions[state]:
            state = links[state]
            match = lengths[state]
        if symbol in transitions[state]:
            state = transitions[state][symbol]
            match += 1
        else:
            state = match = 0
        best = max(best, match)
    return best
