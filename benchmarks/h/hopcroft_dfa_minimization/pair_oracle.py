"""Independent pair-distinguishability reference for small complete DFAs."""


def count_classes(values):
    n, alphabet = values[:2]
    if not 1 <= n <= 16 or not 1 <= alphabet <= 4 or len(values) != 2 + n * (alphabet + 1):
        raise ValueError("pair reference requires a valid small DFA frame")
    flags = values[2:2+n]
    transitions = values[2+n:]
    if any(x not in (0, 1) for x in flags) or any(not 0 <= x < n for x in transitions):
        raise ValueError("pair reference requires valid flags and transitions")
    different = [[flags[a] != flags[b] for b in range(n)] for a in range(n)]
    changed = True
    while changed:
        changed = False
        for a in range(n):
            for b in range(a):
                if not different[a][b] and any(
                    different[transitions[a*alphabet+c]][transitions[b*alphabet+c]]
                    for c in range(alphabet)
                ):
                    different[a][b] = different[b][a] = True
                    changed = True
    representatives = []
    for state in range(n):
        if all(different[state][other] for other in representatives):
            representatives.append(state)
    return len(representatives)
