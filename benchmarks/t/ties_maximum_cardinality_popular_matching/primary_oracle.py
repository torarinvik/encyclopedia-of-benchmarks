"""Clean-room bounded implementation of tied-list maximum-cardinality popularity."""

from __future__ import annotations

from collections.abc import Sequence

MAX_APPLICANTS = 4
MAX_POSTS = 4
MAX_EDGES = MAX_APPLICANTS * MAX_POSTS
MAX_VALID_INPUT_LENGTH = 3 + 3 * MAX_EDGES
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_RESULT = 4
INVALID_RESULT = -1


def _parse(values: Sequence[int] | None, input_is_null: bool,
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
            rank = ranks[applicant][post]
            if rank:
                counts[rank] += 1
        present = {rank for rank in range(1, posts + 1) if counts[rank]}
        if not present or present != set(range(1, max_rank[applicant] + 1)):
            return None
        has_tie |= any(counts[rank] > 1 for rank in present)
    if not has_tie:
        return None
    return applicants, posts, ranks


def _maximum_matching(applicants: int, right_count: int,
                      edges: list[list[bool]], initial: list[int] | None = None
                      ) -> tuple[list[int], list[int]]:
    left_owner = (initial[:] if initial is not None else [-1] * applicants)
    right_owner = [-1] * right_count
    for applicant, post in enumerate(left_owner):
        if post >= 0:
            if post >= right_count or right_owner[post] >= 0 or not edges[applicant][post]:
                return [-1] * applicants, [-1] * right_count
            right_owner[post] = applicant

    def augment(applicant: int, seen: list[bool]) -> bool:
        for post in range(right_count):
            if not edges[applicant][post] or seen[post]:
                continue
            seen[post] = True
            previous = right_owner[post]
            if previous < 0 or augment(previous, seen):
                right_owner[post] = applicant
                left_owner[applicant] = post
                return True
        return False

    while True:
        changed = False
        for applicant in range(applicants):
            if left_owner[applicant] < 0 and augment(applicant, [False] * right_count):
                changed = True
        if not changed:
            return left_owner, right_owner


def _solve(applicants: int, posts: int, ranks: list[list[int]]) -> int:
    right_count = posts + applicants
    first_edges = [[False] * right_count for _ in range(applicants)]
    for applicant in range(applicants):
        for post in range(posts):
            first_edges[applicant][post] = ranks[applicant][post] == 1
    first_left, first_right = _maximum_matching(applicants, right_count, first_edges)
    first_size = sum(post >= 0 for post in first_left)

    # Even/odd/unreachable classes from all exposed vertices of the first-choice graph.
    state = [-1] * (applicants + right_count)
    queue: list[int] = []
    for applicant in range(applicants):
        if first_left[applicant] < 0:
            state[applicant] = 0
            queue.append(applicant)
    for post in range(posts):
        if first_right[post] < 0:
            node = applicants + post
            state[node] = 0
            queue.append(node)
    for applicant in range(applicants):
        node = applicants + posts + applicant
        state[node] = 0
        queue.append(node)

    cursor = 0
    while cursor < len(queue):
        node = queue[cursor]
        cursor += 1
        if node < applicants:
            applicant = node
            if state[node] == 0:
                for post in range(posts):
                    if ranks[applicant][post] == 1 and first_left[applicant] != post:
                        target = applicants + post
                        if state[target] < 0:
                            state[target] = 1
                            queue.append(target)
            elif first_left[applicant] >= 0:
                target = applicants + first_left[applicant]
                if state[target] < 0:
                    state[target] = 0
                    queue.append(target)
        else:
            post = node - applicants
            if post < posts:
                if state[node] == 0:
                    for applicant in range(applicants):
                        if ranks[applicant][post] == 1 and first_left[applicant] != post:
                            if state[applicant] < 0:
                                state[applicant] = 1
                                queue.append(applicant)
                elif first_right[post] >= 0:
                    target = first_right[post]
                    if state[target] < 0:
                        state[target] = 0
                        queue.append(target)

    classes = [value if value >= 0 else 2 for value in state]
    reduced = [[False] * right_count for _ in range(applicants)]
    for applicant in range(applicants):
        best_even_rank = posts + 1
        for post in range(posts):
            if ranks[applicant][post] and classes[applicants + post] == 0:
                best_even_rank = min(best_even_rank, ranks[applicant][post])
        last_rank = max(rank for rank in ranks[applicant][:posts] if rank > 0) + 1
        if classes[applicants + posts + applicant] == 0:
            best_even_rank = min(best_even_rank, last_rank)
        for post in range(posts):
            if ranks[applicant][post] == 1:
                reduced[applicant][post] = True
            if (ranks[applicant][post] > 0
                    and ranks[applicant][post] == best_even_rank
                    and classes[applicants + post] == 0):
                reduced[applicant][post] = True
        if last_rank == best_even_rank and classes[applicants + posts + applicant] == 0:
            reduced[applicant][posts + applicant] = True

    allowed = [[False] * right_count for _ in range(applicants)]
    for applicant in range(applicants):
        for post in range(right_count):
            if not reduced[applicant][post]:
                continue
            applicant_class = classes[applicant]
            post_class = classes[applicants + post]
            if applicant_class == 1 and post_class in (1, 2):
                continue
            if applicant_class == 2 and post_class == 1:
                continue
            allowed[applicant][post] = True

    popular_left, _ = _maximum_matching(applicants, right_count, allowed, first_left)
    if any(post < 0 for post in popular_left):
        return 0
    popular_rank_one = sum(post < posts and ranks[a][post] == 1
                           for a, post in enumerate(popular_left))
    if popular_rank_one != first_size:
        return 0

    # Section 3.2: maximize non-last-resort assignments in H, then augment
    # again in G' to restore applicant completeness. Rank-one cardinality is
    # checked after both bounded deterministic augmentation phases.
    real_edges = [[allowed[a][p] if p < posts else False for p in range(right_count)]
                  for a in range(applicants)]
    initial_real = [post if post < posts else -1 for post in popular_left]
    real_left, _ = _maximum_matching(applicants, right_count, real_edges, initial_real)
    real_rank_one = sum(post < posts and ranks[a][post] == 1
                        for a, post in enumerate(real_left) if post >= 0)
    if real_rank_one != first_size:
        return 0

    final_left, _ = _maximum_matching(applicants, right_count, allowed, real_left)
    if any(post < 0 for post in final_left):
        return 0
    final_rank_one = sum(post < posts and ranks[a][post] == 1
                         for a, post in enumerate(final_left))
    if final_rank_one != first_size:
        return 0
    return sum(post < posts for post in final_left)


def expected_result(values: Sequence[int] | None, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    parsed = _parse(values, input_is_null, input_length)
    if parsed is None:
        return INVALID_RESULT
    applicants, posts, ranks = parsed
    return _solve(applicants, posts, ranks)
