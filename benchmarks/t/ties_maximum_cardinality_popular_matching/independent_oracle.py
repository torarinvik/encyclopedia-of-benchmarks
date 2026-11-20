"""Brute-force reference using the direct pairwise-vote definition."""

from __future__ import annotations

from collections.abc import Sequence

MAX_APPLICANTS = 4
MAX_POSTS = 4
MAX_VALID_INPUT_LENGTH = 3 + 3 * MAX_APPLICANTS * MAX_POSTS
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
INVALID_RESULT = -1


def _read(values: Sequence[int] | None, input_is_null: bool,
          input_length: int | None) -> tuple[int, int, list[list[int]]] | None:
    if (type(input_is_null) is not bool or input_is_null or values is None
            or not isinstance(values, (list, tuple))
            or not 3 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
            or (input_length is not None
                and (type(input_length) is not int or input_length != len(values)))
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return None
    applicants, posts, edge_count = values[:3]
    if not 1 <= applicants <= MAX_APPLICANTS or not 1 <= posts <= MAX_POSTS:
        return None
    if not applicants <= edge_count <= applicants * posts or len(values) != 3 + 3 * edge_count:
        return None
    ranks = [[0] * MAX_POSTS for _ in range(MAX_APPLICANTS)]
    max_rank = [0] * MAX_APPLICANTS
    cursor = 3
    for _ in range(edge_count):
        applicant, post, rank = values[cursor:cursor + 3]
        cursor += 3
        if not (0 <= applicant < applicants and 0 <= post < posts and 1 <= rank <= posts):
            return None
        if ranks[applicant][post] != 0:
            return None
        ranks[applicant][post] = rank
        max_rank[applicant] = max(max_rank[applicant], rank)
    has_tie = False
    for applicant in range(applicants):
        counts = [0] * (posts + 1)
        for post in range(posts):
            if ranks[applicant][post]:
                counts[ranks[applicant][post]] += 1
        present = {rank for rank in range(1, posts + 1) if counts[rank]}
        if not present or present != set(range(1, max_rank[applicant] + 1)):
            return None
        has_tie |= any(counts[rank] > 1 for rank in present)
    if not has_tie:
        return None
    return applicants, posts, ranks


def _enumerate_popular_size(applicants: int, posts: int,
                            ranks: list[list[int]]) -> int:
    last_rank = [max(rank for rank in ranks[a][:posts] if rank > 0) + 1
                 for a in range(applicants)]
    choices = [[p for p in range(posts) if ranks[a][p] > 0] + [posts + a]
               for a in range(applicants)]
    occupied: set[int] = set()
    assignment = [-1] * applicants
    alternatives: list[tuple[int, ...]] = []

    def enumerate_complete(a: int) -> None:
        if a == applicants:
            alternatives.append(tuple(assignment))
            return
        for post in choices[a]:
            if post in occupied:
                continue
            occupied.add(post)
            assignment[a] = post
            enumerate_complete(a + 1)
            occupied.remove(post)
        assignment[a] = -1

    enumerate_complete(0)
    best = 0
    for candidate in alternatives:
        popular = True
        for other in alternatives:
            votes_for_candidate = 0
            for a in range(applicants):
                candidate_rank = ranks[a][candidate[a]] if candidate[a] < posts else last_rank[a]
                other_rank = ranks[a][other[a]] if other[a] < posts else last_rank[a]
                votes_for_candidate += (candidate_rank < other_rank) - (candidate_rank > other_rank)
            if votes_for_candidate < 0:
                popular = False
                break
        if popular:
            best = max(best, sum(post < posts for post in candidate))
    return best


def expected_result(values: Sequence[int] | None, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    parsed = _read(values, input_is_null, input_length)
    if parsed is None:
        return INVALID_RESULT
    applicants, posts, ranks = parsed
    return _enumerate_popular_size(applicants, posts, ranks)
