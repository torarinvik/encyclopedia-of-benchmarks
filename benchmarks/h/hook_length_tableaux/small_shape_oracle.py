"""Independent small-shape oracle using removable-corner recurrence."""
from functools import lru_cache


@lru_cache(maxsize=None)
def count_tableaux(shape):
    if not shape:
        return 1
    total = 0
    for row, width in enumerate(shape):
        if row + 1 < len(shape) and shape[row + 1] == width:
            continue
        reduced = list(shape)
        reduced[row] -= 1
        if reduced[-1] == 0:
            reduced.pop()
        total += count_tableaux(tuple(reduced))
    return total
