"""Independent exhaustive matcher using the direct super-stability definition."""

from __future__ import annotations

from collections.abc import Sequence
from itertools import product

MAX_N = 4
MAX_VALID_INPUT_LENGTH = 1 + 2 * MAX_N * MAX_N
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1


def _parse(values: Sequence[int] | None, input_is_null: bool,
           input_length: int | None) -> tuple[int, list[list[int]], list[list[int]]] | None:
    if type(input_is_null) is not bool or input_is_null:
        return None
    if not isinstance(values, (list, tuple)) or not 1 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH:
        return None
    if any(type(word) is not int or not -(1 << 63) <= word < (1 << 63) for word in values):
        return None
    size = len(values) if input_length is None else input_length
    if type(size) is not int or size != len(values):
        return None
    n = values[0]
    if type(n) is not int or not 1 <= n <= MAX_N or size != 1 + 2 * n * n:
        return None
    offset = 1 + n * n
    men = [[values[1 + m * n + w] for w in range(n)] for m in range(n)]
    women = [[values[offset + w * n + m] for m in range(n)] for w in range(n)]
    if any(rank < 0 or rank > n for row in men + women for rank in row):
        return None
    if any((men[m][w] > 0) != (women[w][m] > 0)
           for m in range(n) for w in range(n)):
        return None
    for matrix in (men, women):
        for row in matrix:
            ranks = {rank for rank in row if rank > 0}
            if ranks and ranks != set(range(1, max(ranks) + 1)):
                return None
    return n, men, women


def _encoding(assignment: tuple[int, ...], n: int) -> int:
    code = 0
    for partner in assignment:
        code = code * (n + 1) + partner
    return code


def _is_super_stable(assignment: tuple[int, ...], n: int,
                     men: list[list[int]], women: list[list[int]]) -> bool:
    inverse = [n] * n
    for man, woman in enumerate(assignment):
        if woman < n:
            if men[man][woman] == 0 or inverse[woman] != n:
                return False
            inverse[woman] = man
    for man in range(n):
        for woman in range(n):
            if men[man][woman] == 0 or assignment[man] == woman:
                continue
            man_weakly_prefers = (assignment[man] == n
                                  or men[man][woman] <= men[man][assignment[man]])
            incumbent = inverse[woman]
            woman_weakly_prefers = (incumbent == n
                                    or women[woman][man] <= women[woman][incumbent])
            if man_weakly_prefers and woman_weakly_prefers:
                return False
    return True


def expected_result(values: Sequence[int] | None, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    parsed = _parse(values, input_is_null, input_length)
    if parsed is None:
        return -1
    n, men, women = parsed
    best: tuple[int, tuple[int, ...]] | None = None
    # Product order is lexicographic in applicant order; the explicit max-size
    # key matches the source theorem that all super-stable matchings match the
    # same people, and makes the reference robust on the finite domain.
    for assignment in product(range(n + 1), repeat=n):
        if not _is_super_stable(assignment, n, men, women):
            continue
        cardinality = sum(partner < n for partner in assignment)
        candidate = (cardinality, assignment)
        if (best is None or cardinality > best[0]
                or (cardinality == best[0] and assignment < best[1])):
            best = candidate
    if best is None:
        return -2
    return _encoding(best[1], n)


def verify_candidate(values: Sequence[int] | None, result: int,
                     input_is_null: bool = False,
                     input_length: int | None = None) -> bool:
    return (type(result) is int
            and result == expected_result(values, input_is_null, input_length))
