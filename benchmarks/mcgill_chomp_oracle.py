"""Independent outcome oracle for the pinned McGill Chomp launcher profiles."""

from __future__ import annotations

from functools import lru_cache

MIN_ROWS = 7
MAX_ROWS = 8
COLUMNS = 7
INVALID_RESULT = -1


def expected_result(rows: int) -> int:
    """Return 1 if the first player wins the source's fixed-width board."""
    if type(rows) is not int or rows not in (MIN_ROWS, MAX_ROWS):
        return INVALID_RESULT

    @lru_cache(maxsize=None)
    def position_value(state: tuple[int, ...]) -> int:
        has_move = False
        for row in range(rows):
            for column in range(COLUMNS):
                successor = list(state)
                for index in range(column, COLUMNS):
                    successor[index] = min(successor[index], row)
                next_state = tuple(successor)
                if next_state == state:
                    continue
                has_move = True
                if position_value(next_state) == 0:
                    return 1
        # The empty state means the previous player took the poison square;
        # the player now to move wins, matching make_list's no-moves value 1.
        return 0 if has_move else 1

    return position_value((rows,) * COLUMNS)
