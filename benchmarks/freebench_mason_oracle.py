"""Independent bounded oracle for FreeBench Mason's alternating transform search."""

from __future__ import annotations

from collections.abc import Sequence

PIECE_COUNT = 9
POSITION_COUNT = 18
MAX_DEPTH = 8
MAX_INPUT_LENGTH = PIECE_COUNT
MAX_PARSEABLE_INPUT_LENGTH = PIECE_COUNT + 1
INVALID_RESULT = -1
NO_SOLUTION_WITHIN_BOUND = -2

UP = (
    (0, 8, 1, 2, 16, 5, 13, 7, 14, 9, 3, 4, 11, 12, 15, 10, 17, 6),
    tuple(range(POSITION_COUNT)),
    (1, 2, 9, 10, 4, 17, 6, 0, 8, 15, 11, 12, 5, 13, 7, 14, 3, 16),
)
DOWN = (
    (0, 2, 3, 10, 11, 5, 17, 7, 1, 9, 15, 12, 13, 6, 8, 14, 4, 16),
    tuple(range(POSITION_COUNT)),
    (7, 0, 1, 16, 4, 12, 6, 14, 8, 2, 3, 10, 11, 13, 15, 9, 17, 5),
)


def _is_goal(state: tuple[int, ...]) -> bool:
    return (state[0] == 5 and state[1] == 6 and state[2] == 12
            and state[3] == 13 and state[4] == 14 and state[5] == 15
            and state[6] + state[7] + state[8] == 3)


def expected_result(values: Sequence[int]) -> int:
    """Return the first even search bound that reaches the goal, or -2 at depth 8.

    The oracle explores states breadth-first and does not use the source's
    per-piece four-step pruning table, so it checks the result independently
    of the recursive implementation strategy.
    """
    if (not isinstance(values, (list, tuple))
            or len(values) > MAX_PARSEABLE_INPUT_LENGTH
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return INVALID_RESULT
    if len(values) != PIECE_COUNT:
        return INVALID_RESULT
    if (any(position < 0 or position >= POSITION_COUNT for position in values)
            or len(set(values)) != PIECE_COUNT):
        return INVALID_RESULT

    start = tuple(values)
    if _is_goal(start):
        return 2  # The source's first iterative-deepening pass is k=2.

    frontier = {(start, -1)}
    for depth in range(MAX_DEPTH):
        next_frontier: set[tuple[tuple[int, ...], int]] = set()
        moves = UP if depth % 2 == 0 else DOWN
        for state, last_move in frontier:
            for move, mapping in enumerate(moves):
                if move == last_move:
                    continue
                successor = tuple(mapping[position] for position in state)
                next_depth = depth + 1
                if next_depth % 2 == 0 and _is_goal(successor):
                    return max(2, next_depth)
                next_frontier.add((successor, move))
        frontier = next_frontier
        if not frontier:
            break
    return NO_SOLUTION_WITHIN_BOUND
