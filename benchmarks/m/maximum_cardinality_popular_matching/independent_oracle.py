"""Assignment-enumeration reference using the popular-matching theorem."""

from __future__ import annotations

from collections.abc import Sequence
from itertools import product

MAX_APPLICANTS = 6
MAX_POSTS = 6
MAX_VALID_INPUT_LENGTH = 2 + MAX_APPLICANTS + MAX_APPLICANTS * MAX_POSTS
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
INVALID_RESULT = -1


def _read(values: Sequence[int] | None, input_is_null: bool,
          input_length: int | None) -> tuple[int, int, tuple[tuple[int, ...], ...]] | None:
    if type(input_is_null) is not bool or input_is_null or values is None:
        return None
    if not isinstance(values, (list, tuple)) or len(values) < 2:
        return None
    if len(values) > MAX_PARSEABLE_INPUT_LENGTH:
        return None
    if input_length is not None and (type(input_length) is not int or input_length != len(values)):
        return None
    if any(type(value) is not int or value < -(1 << 63) or value >= (1 << 63)
           for value in values):
        return None
    applicant_count, post_count = values[0], values[1]
    if not 1 <= applicant_count <= MAX_APPLICANTS or not 1 <= post_count <= MAX_POSTS:
        return None
    if len(values) < 2 + applicant_count:
        return None
    sizes = tuple(values[2:2 + applicant_count])
    if any(size < 1 or size > post_count for size in sizes):
        return None
    if len(values) != 2 + applicant_count + sum(sizes):
        return None
    rows: list[tuple[int, ...]] = []
    offset = 2 + applicant_count
    for size in sizes:
        row = tuple(values[offset:offset + size])
        offset += size
        if any(post < 0 or post >= post_count for post in row) or len(set(row)) != size:
            return None
        rows.append(row)
    return applicant_count, post_count, tuple(rows)


def _enumerated_popular_size(applicants: int, posts: int,
                             preferences: tuple[tuple[int, ...], ...]) -> int:
    first = tuple(row[0] for row in preferences)
    first_posts = set(first)
    second = tuple(next((post for post in row if post not in first_posts), posts + a)
                   for a, row in enumerate(preferences))
    best = 0
    assignment = [-1] * applicants
    occupied: set[int] = set()

    def visit(applicant: int, real_count: int) -> None:
        nonlocal best
        if applicant == applicants:
            # The strict-list characterization: all f-posts are covered and
            # every applicant receives f(a) or its first non-f-post s(a).
            if all(post in occupied for post in first_posts):
                best = max(best, real_count)
            return
        for post in (first[applicant], second[applicant]):
            if post < posts and post in occupied:
                continue
            assignment[applicant] = post
            if post < posts:
                occupied.add(post)
                visit(applicant + 1, real_count + 1)
                occupied.remove(post)
            else:
                visit(applicant + 1, real_count)
        assignment[applicant] = -1

    visit(0, 0)
    return best


def expected_result(values: Sequence[int] | None, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    parsed = _read(values, input_is_null, input_length)
    if parsed is None:
        return INVALID_RESULT
    applicants, posts, preferences = parsed
    return _enumerated_popular_size(applicants, posts, preferences)
