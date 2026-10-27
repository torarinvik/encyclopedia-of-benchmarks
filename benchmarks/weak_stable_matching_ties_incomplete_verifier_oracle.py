"""Independent exhaustive stable-matching verifier for DOI 805."""

from __future__ import annotations

import struct
from collections.abc import Sequence

MAX_N = 6
MAX_INPUT_LENGTH = 73


def _decode(values: Sequence[int] | None):
    if not isinstance(values, (list, tuple)) or not 1 <= len(values) <= MAX_INPUT_LENGTH:
        return None
    if any(type(item) is not int or item < -(1 << 63) or item >= (1 << 63) for item in values):
        return None
    n = values[0]
    if not 1 <= n <= MAX_N or len(values) != 1 + 2 * n * n:
        return None
    offset = 1 + n * n
    men_rank = tuple(tuple(values[1 + m * n + w] for w in range(n)) for m in range(n))
    woman_rank = tuple(tuple(values[offset + w * n + m] for m in range(n)) for w in range(n))
    for m in range(n):
        for w in range(n):
            if (not 0 <= men_rank[m][w] <= n or not 0 <= woman_rank[w][m] <= n
                    or (men_rank[m][w] > 0) != (woman_rank[w][m] > 0)):
                return None
    return n, men_rank, woman_rank


def _strict_key(rank: int, participant: int, n: int) -> tuple[int, int]:
    return (rank, participant) if rank > 0 else (n + 1, n + 1)


def _stable_in_refinement(matching: tuple[int, ...], n: int,
                          men: tuple[tuple[int, ...], ...],
                          women: tuple[tuple[int, ...], ...]) -> bool:
    woman_partner = [-1] * n
    for man, woman in enumerate(matching):
        if woman >= 0:
            if woman_partner[woman] >= 0:
                return False
            woman_partner[woman] = man
    for man in range(n):
        current_woman = matching[man]
        current_man_key = _strict_key(men[man][current_woman], current_woman, n) if current_woman >= 0 else (n + 1, n + 1)
        for woman in range(n):
            if men[man][woman] == 0 or matching[man] == woman:
                continue
            incumbent = woman_partner[woman]
            current_woman_key = _strict_key(women[woman][incumbent], incumbent, n) if incumbent >= 0 else (n + 1, n + 1)
            if (_strict_key(men[man][woman], woman, n) < current_man_key
                    and _strict_key(women[woman][man], man, n) < current_woman_key):
                return False
    return True


def _weakly_stable(matching: tuple[int, ...], n: int,
                   men: tuple[tuple[int, ...], ...],
                   women: tuple[tuple[int, ...], ...]) -> bool:
    woman_partner = [-1] * n
    for man, woman in enumerate(matching):
        if woman >= 0:
            woman_partner[woman] = man
    for man in range(n):
        current_woman = matching[man]
        for woman in range(n):
            if men[man][woman] == 0 or matching[man] == woman:
                continue
            incumbent = woman_partner[woman]
            man_better = current_woman < 0 or men[man][woman] < men[man][current_woman]
            woman_better = incumbent < 0 or women[woman][man] < women[woman][incumbent]
            if man_better and woman_better:
                return False
    return True


def _enumerate_best(n: int, men: tuple[tuple[int, ...], ...],
                    women: tuple[tuple[int, ...], ...]) -> list[int]:
    assignment = [-1] * n
    used = [False] * n
    best_key: tuple[tuple[int, int], ...] | None = None
    best: tuple[int, ...] | None = None

    def visit(man: int) -> None:
        nonlocal best_key, best
        if man == n:
            candidate = tuple(assignment)
            if not _stable_in_refinement(candidate, n, men, women) or not _weakly_stable(candidate, n, men, women):
                return
            key = tuple(_strict_key(men[m][w], w, n) if w >= 0 else (n + 1, n + 1)
                        for m, w in enumerate(candidate))
            if best_key is None or key < best_key:
                best_key, best = key, candidate
            return
        assignment[man] = -1
        visit(man + 1)
        for woman in range(n):
            if men[man][woman] > 0 and not used[woman]:
                used[woman] = True
                assignment[man] = woman
                visit(man + 1)
                used[woman] = False
        assignment[man] = -1

    visit(0)
    if best is None:
        return [0]
    pairs = [(man, woman) for man, woman in enumerate(best) if woman >= 0]
    return [len(pairs), *(item for pair in pairs for item in pair)]


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or capacity is not None and (type(capacity) is not int or capacity < 0)
            or input_length is not None and (type(input_length) is not int
                                             or not 0 <= input_length <= MAX_INPUT_LENGTH)
            or input_is_null and values not in (None, [], ())
            or not input_is_null and values is not None and input_length is not None
            and input_length != len(values)):
        return -1, b""
    if input_is_null or values is None:
        return -1, b""
    decoded = _decode(values)
    if decoded is None:
        return -1, b""
    n, men, women = decoded
    words = _enumerate_best(n, men, women)
    payload = struct.pack("<" + "q" * len(words), *words)
    if output_is_null or capacity is not None and capacity < len(payload):
        return -2, b""
    return len(payload), payload
