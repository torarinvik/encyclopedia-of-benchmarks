"""Move-count oracle for the pinned egg-dropping dynamic program."""

from __future__ import annotations

I64_MIN = -(2**63)
I64_MAX = 2**63 - 1
MAX_EGGS = 8
MAX_FLOORS = 32


def expected_result(values: list[int] | tuple[int, ...]) -> int:
    if (not isinstance(values, (list, tuple)) or len(values) != 2
            or any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values)):
        return -1
    eggs, floors = values
    if not 1 <= eggs <= MAX_EGGS or not 1 <= floors <= MAX_FLOORS:
        return -1

    # Track how many floor levels can be distinguished with each egg count
    # after a given number of drops. This is independent of the source's
    # eggs-by-floors minimax table.
    reachable = [0] * (eggs + 1)
    trials = 0
    while reachable[eggs] < floors:
        trials += 1
        for egg_count in range(eggs, 0, -1):
            reachable[egg_count] += reachable[egg_count - 1] + 1
    return trials
