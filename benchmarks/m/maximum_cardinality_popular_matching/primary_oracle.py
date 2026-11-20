"""Degree/cycle reduced-graph profile for maximum-cardinality popularity."""

from __future__ import annotations

from collections.abc import Sequence

MAX_APPLICANTS = 6
MAX_POSTS = 6
MAX_VALID_INPUT_LENGTH = 2 + MAX_APPLICANTS + MAX_APPLICANTS * MAX_POSTS
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_RESULT = MAX_APPLICANTS
INVALID_RESULT = -1


def _parse(values: Sequence[int] | None, input_is_null: bool,
           input_length: int | None) -> tuple[int, int, list[list[int]]] | None:
    if (type(input_is_null) is not bool or input_is_null or values is None
            or not isinstance(values, (list, tuple))
            or not 2 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
            or (input_length is not None
                and (type(input_length) is not int or input_length != len(values)))
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return None
    applicants, posts = values[:2]
    if not 1 <= applicants <= MAX_APPLICANTS or not 1 <= posts <= MAX_POSTS:
        return None
    if len(values) < 2 + applicants:
        return None
    lengths = values[2:2 + applicants]
    if any(not 1 <= size <= posts for size in lengths):
        return None
    if len(values) != 2 + applicants + sum(lengths):
        return None
    preferences: list[list[int]] = []
    cursor = 2 + applicants
    for size in lengths:
        row = list(values[cursor:cursor + size])
        cursor += size
        if (any(not 0 <= post < posts for post in row)
                or len(set(row)) != size):
            return None
        preferences.append(row)
    return applicants, posts, preferences


def _reduced_choices(preferences: list[list[int]], posts: int
                     ) -> tuple[list[int], list[int], list[bool]]:
    first = [row[0] for row in preferences]
    is_first_post = [False] * posts
    for post in first:
        is_first_post[post] = True
    second: list[int] = []
    for applicant, row in enumerate(preferences):
        choice = next((post for post in row if not is_first_post[post]), posts + applicant)
        second.append(choice)
    return first, second, is_first_post


def _applicant_complete_a2(applicants: int, posts: int, first: list[int],
                           second: list[int]) -> list[int] | None:
    """Force degree-one posts, then match each residual 2-regular cycle."""
    active_applicant = [second[a] < posts for a in range(applicants)]
    active_post = [True] * posts
    assignment = [-1] * applicants

    while True:
        degree = [0] * posts
        sole_applicant = [-1] * posts
        for a in range(applicants):
            if not active_applicant[a]:
                continue
            for post in (first[a], second[a]):
                if active_post[post]:
                    degree[post] += 1
                    sole_applicant[post] = a
        forced_post = next((p for p in range(posts) if active_post[p] and degree[p] == 1), -1)
        if forced_post < 0:
            break
        applicant = sole_applicant[forced_post]
        assignment[applicant] = forced_post
        active_applicant[applicant] = False
        active_post[forced_post] = False

    degree = [0] * posts
    post_neighbors: list[list[int]] = [[] for _ in range(posts)]
    active_applicants = [a for a in range(applicants) if active_applicant[a]]
    for a in active_applicants:
        for post in (first[a], second[a]):
            if active_post[post]:
                degree[post] += 1
                post_neighbors[post].append(a)
    residual_posts = [p for p in range(posts) if active_post[p] and degree[p] > 0]
    if len(residual_posts) < len(active_applicants):
        return None
    if (len(residual_posts) != len(active_applicants)
            or any(degree[p] != 2 for p in residual_posts)
            or any(not active_post[first[a]] or not active_post[second[a]]
                   for a in active_applicants)):
        return None

    visited = [False] * applicants
    for root in active_applicants:
        if visited[root]:
            continue
        first_post = min(first[root], second[root])
        assignment[root] = first_post
        visited[root] = True
        current_applicant = root
        current_post = first_post
        while True:
            neighbors = post_neighbors[current_post]
            next_applicant = neighbors[0] if neighbors[0] != current_applicant else neighbors[1]
            if next_applicant == root:
                break
            next_post = second[next_applicant] if first[next_applicant] == current_post else first[next_applicant]
            if visited[next_applicant]:
                return None
            assignment[next_applicant] = next_post
            visited[next_applicant] = True
            current_applicant, current_post = next_applicant, next_post
    return assignment


def _maximum_popular_size(applicants: int, posts: int,
                          preferences: list[list[int]]) -> int:
    first, second, is_first_post = _reduced_choices(preferences, posts)
    a2_assignment = _applicant_complete_a2(applicants, posts, first, second)
    if a2_assignment is None:
        return 0

    assignment = a2_assignment[:]
    owner = [-1] * posts
    for applicant, post in enumerate(assignment):
        if post >= 0:
            owner[post] = applicant

    def augment(applicant: int, seen_post: list[bool]) -> bool:
        edges = [first[applicant]]
        if second[applicant] < posts:
            edges.append(second[applicant])
        edges.sort()
        for post in edges:
            if seen_post[post]:
                continue
            seen_post[post] = True
            previous = owner[post]
            if previous < 0 or augment(previous, seen_post):
                owner[post] = applicant
                assignment[applicant] = post
                return True
        return False

    for applicant in range(applicants):
        if second[applicant] >= posts and assignment[applicant] < 0:
            augment(applicant, [False] * posts)

    for applicant in range(applicants):
        if assignment[applicant] < 0:
            assignment[applicant] = posts + applicant

    # The source's final promotion step covers every first-choice post.
    for post in range(posts):
        if is_first_post[post] and owner[post] < 0:
            applicant = next(a for a in range(applicants) if first[a] == post)
            previous = assignment[applicant]
            if previous < posts:
                owner[previous] = -1
            assignment[applicant] = post
            owner[post] = applicant

    return sum(post < posts for post in assignment)


def expected_result(values: Sequence[int] | None, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    parsed = _parse(values, input_is_null, input_length)
    if parsed is None:
        return INVALID_RESULT
    applicants, posts, preferences = parsed
    return _maximum_popular_size(applicants, posts, preferences)
