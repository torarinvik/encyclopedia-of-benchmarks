"""Independent subset enumeration of all convex-polygon triangulations."""

from itertools import combinations

from .primary_oracle import _crosses, _diagonals, _parse


def expected_result(values):
    parsed = _parse(values)
    if parsed is None:
        return -1
    n, _, _, _, _ = parsed
    candidates = _diagonals(n)
    total = 0
    for selection in combinations(candidates, n - 3):
        if any(_crosses(selection[i], selection[j])
               for i in range(len(selection)) for j in range(i + 1, len(selection))):
            continue
        total += 1
    return total
