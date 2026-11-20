"""Bounded SUPER2 proposal/elimination algorithm for super-stable matching."""

from __future__ import annotations

from collections.abc import Sequence

MAX_N = 4
MAX_VALID_INPUT_LENGTH = 1 + 2 * MAX_N * MAX_N
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
INVALID_RESULT = -1
NO_SUPER_STABLE_RESULT = -2


def _decode(values: Sequence[int] | None, input_is_null: bool,
            input_length: int | None) -> tuple[int, list[list[int]], list[list[int]]] | None:
    if type(input_is_null) is not bool or input_is_null:
        return None
    if not isinstance(values, (list, tuple)) or not 1 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH:
        return None
    if any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
           for value in values):
        return None
    actual_length = len(values) if input_length is None else input_length
    if type(actual_length) is not int or actual_length != len(values):
        return None
    n = values[0]
    if type(n) is not int or not 1 <= n <= MAX_N or len(values) != 1 + 2 * n * n:
        return None
    side = n * n
    men = [[0] * n for _ in range(n)]
    women = [[0] * n for _ in range(n)]
    for man in range(n):
        for woman in range(n):
            rank = values[1 + man * n + woman]
            if not 0 <= rank <= n:
                return None
            men[man][woman] = rank
    for woman in range(n):
        for man in range(n):
            rank = values[1 + side + woman * n + man]
            if not 0 <= rank <= n or ((rank > 0) != (men[man][woman] > 0)):
                return None
            women[woman][man] = rank
    for ranks in (men, women):
        for person in ranks:
            present = {rank for rank in person if rank > 0}
            if present and present != set(range(1, max(present) + 1)):
                return None
    return n, men, women


def _encode_assignment(assignment: tuple[int, ...], n: int) -> int:
    base = n + 1
    result = 0
    for partner in assignment:
        result = result * base + partner
    return result


def _least_maximum_matching(engaged: list[list[bool]], n: int) -> tuple[int, ...]:
    assignment = [n] * n
    best_assignment = tuple([n] * n)
    best_size = -1

    def visit(man: int, used: int, size: int) -> None:
        nonlocal best_assignment, best_size
        if man == n:
            candidate = tuple(assignment)
            if size > best_size or (size == best_size and candidate < best_assignment):
                best_size = size
                best_assignment = candidate
            return
        for woman in range(n):
            if engaged[man][woman] and not (used >> woman) & 1:
                assignment[man] = woman
                visit(man + 1, used | (1 << woman), size + 1)
        assignment[man] = n
        visit(man + 1, used, size)

    visit(0, 0, 0)
    return best_assignment


def _super2(n: int, men_rank: list[list[int]],
            women_rank: list[list[int]]) -> int:
    # `alive` is the reduced preference graph. `engaged` is the current
    # relation, and `proposed` records women who have ever received a proposal.
    alive = [[men_rank[m][w] > 0 for w in range(n)] for m in range(n)]
    engaged = [[False] * n for _ in range(n)]
    proposed_woman = [False] * n

    while True:
        proposer = -1
        for man in range(n):
            if any(engaged[man]):
                continue
            if any(alive[man][woman] for woman in range(n)):
                proposer = man
                break
        if proposer < 0:
            break

        head_rank = min(men_rank[proposer][woman]
                        for woman in range(n) if alive[proposer][woman])
        head = [woman for woman in range(n)
                if alive[proposer][woman]
                and men_rank[proposer][woman] == head_rank]
        for woman in head:
            proposed_woman[woman] = True
            engaged[proposer][woman] = True
            for successor in range(n):
                if (alive[successor][woman]
                        and women_rank[woman][successor] > women_rank[woman][proposer]):
                    engaged[successor][woman] = False
                    alive[successor][woman] = False

        for woman in range(n):
            current = [man for man in range(n) if engaged[man][woman]]
            if len(current) <= 1:
                continue
            for man in current:
                engaged[man][woman] = False
            tail_rank = max(women_rank[woman][man]
                            for man in range(n) if alive[man][woman])
            for man in range(n):
                if alive[man][woman] and women_rank[woman][man] == tail_rank:
                    alive[man][woman] = False

    matching = _least_maximum_matching(engaged, n)
    matched_woman = [False] * n
    for woman in matching:
        if woman < n:
            matched_woman[woman] = True
    if any(proposed_woman[w] and not matched_woman[w] for w in range(n)):
        return NO_SUPER_STABLE_RESULT
    return _encode_assignment(matching, n)


def expected_result(values: Sequence[int] | None, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    decoded = _decode(values, input_is_null, input_length)
    if decoded is None:
        return INVALID_RESULT
    n, men_rank, women_rank = decoded
    return _super2(n, men_rank, women_rank)
