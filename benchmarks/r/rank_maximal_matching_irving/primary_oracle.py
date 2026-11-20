"""Bounded rank-phase Irving reduction for bipartite rank-maximal matching."""

from __future__ import annotations

from collections.abc import Sequence
import struct

MAX_APPLICANTS = 4
MAX_POSTS = 4
MAX_RANK = 4
MAX_EDGES = 16
MAX_INPUT_LENGTH = 51
MAX_PARSEABLE_INPUT_LENGTH = 52
MAX_OUTPUT_BYTES = 40
WORKSPACE_BYTES = 1024
INVALID_RESULT = -1
OUTPUT_ERROR_RESULT = -2


def _parse(values: Sequence[int] | None, input_is_null: bool,
           input_length: int | None):
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple))
            or not 3 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return None
    if input_length is None:
        input_length = len(values)
    if type(input_length) is not int or input_length != len(values):
        return None
    applicants, posts, edge_count = values[:3]
    if not 1 <= applicants <= MAX_APPLICANTS or not 1 <= posts <= MAX_POSTS:
        return None
    if not applicants <= edge_count <= min(MAX_EDGES, applicants * posts):
        return None
    if len(values) != 3 + 3 * edge_count:
        return None
    ranks = [[0] * posts for _ in range(applicants)]
    degrees = [0] * applicants
    max_rank = 0
    for offset in range(3, len(values), 3):
        applicant, post, rank = values[offset:offset + 3]
        if (not 0 <= applicant < applicants or not 0 <= post < posts
                or not 1 <= rank <= MAX_RANK or ranks[applicant][post] != 0):
            return None
        ranks[applicant][post] = rank
        degrees[applicant] += 1
        max_rank = max(max_rank, rank)
    if any(degree == 0 for degree in degrees):
        return None
    return applicants, posts, max_rank, ranks


def _lex_less(left: tuple[int, ...], right: tuple[int, ...]) -> bool:
    return left < right


def _maximum_matching(applicants: int, posts: int, phase: int,
                      ranks: list[list[int]], blocked: list[list[bool]]
                      ) -> tuple[list[int], list[int]]:
    """Exhaust the bounded assignment space and select a canonical maximum."""
    base = posts + 1
    best_size = -1
    best_assignment: tuple[int, ...] | None = None
    for code in range(base ** applicants):
        value = code
        assignment: list[int] = []
        used = 0
        size = 0
        valid = True
        for applicant in range(applicants):
            post = value % base
            value //= base
            assignment.append(post)
            if post == posts:
                continue
            if (ranks[applicant][post] == 0 or ranks[applicant][post] > phase
                    or blocked[applicant][post] or used & (1 << post)):
                valid = False
                break
            used |= 1 << post
            size += 1
        candidate = tuple(assignment)
        if valid and (size > best_size or
                      (size == best_size and (best_assignment is None
                                              or _lex_less(candidate, best_assignment)))):
            best_size = size
            best_assignment = candidate
    assert best_assignment is not None
    owner = [-1] * posts
    assignment = [-1] * applicants
    for applicant, post in enumerate(best_assignment):
        if post < posts:
            assignment[applicant] = post
            owner[post] = applicant
    return assignment, owner


def _classes(applicants: int, posts: int, phase: int,
             ranks: list[list[int]], blocked: list[list[bool]],
             assignment: list[int], owner: list[int]) -> list[int]:
    vertex_count = applicants + posts
    classes = [2] * vertex_count  # 0=even, 1=odd, 2=unreachable
    queue: list[int] = []
    for applicant in range(applicants):
        if assignment[applicant] < 0:
            classes[applicant] = 0
            queue.append(applicant)
    for post in range(posts):
        if owner[post] < 0:
            classes[applicants + post] = 0
            queue.append(applicants + post)

    head = 0
    while head < len(queue):
        vertex = queue[head]
        head += 1
        if vertex < applicants:
            applicant = vertex
            if classes[vertex] == 0:
                for post in range(posts):
                    if (ranks[applicant][post] and ranks[applicant][post] <= phase
                            and not blocked[applicant][post]
                            and assignment[applicant] != post
                            and classes[applicants + post] == 2):
                        classes[applicants + post] = 1
                        queue.append(applicants + post)
            elif assignment[applicant] >= 0:
                target = applicants + assignment[applicant]
                if classes[target] == 2:
                    classes[target] = 0
                    queue.append(target)
        else:
            post = vertex - applicants
            if classes[vertex] == 0:
                for applicant in range(applicants):
                    if (ranks[applicant][post] and ranks[applicant][post] <= phase
                            and not blocked[applicant][post]
                            and assignment[applicant] != post
                            and classes[applicant] == 2):
                        classes[applicant] = 1
                        queue.append(applicant)
            elif owner[post] >= 0:
                target = owner[post]
                if classes[target] == 2:
                    classes[target] = 0
                    queue.append(target)
    return classes


def _irving_signature(applicants: int, posts: int, max_rank: int,
                      ranks: list[list[int]]) -> tuple[int, ...]:
    blocked = [[False] * posts for _ in range(applicants)]
    assignment = [-1] * applicants
    owner = [-1] * posts
    for phase in range(1, max_rank + 1):
        assignment, owner = _maximum_matching(applicants, posts, phase, ranks, blocked)
        classes = _classes(applicants, posts, phase, ranks, blocked, assignment, owner)

        # Preserve only edges that can remain in a rank-maximal continuation.
        for applicant in range(applicants):
            for post in range(posts):
                rank = ranks[applicant][post]
                if rank == 0 or blocked[applicant][post]:
                    continue
                left_class = classes[applicant]
                right_class = classes[applicants + post]
                if rank <= phase:
                    if ((left_class == 1 and right_class != 0)
                            or (right_class == 1 and left_class != 0)):
                        blocked[applicant][post] = True
                elif left_class != 0 or right_class != 0:
                    blocked[applicant][post] = True

    signature = [0] * max_rank
    for applicant, post in enumerate(assignment):
        if post >= 0:
            signature[ranks[applicant][post] - 1] += 1
    return tuple(signature)


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    parsed = _parse(values, input_is_null, input_length)
    if parsed is None:
        return INVALID_RESULT, b""
    applicants, posts, max_rank, ranks = parsed
    signature = _irving_signature(applicants, posts, max_rank, ranks)
    payload = struct.pack("<" + "q" * (max_rank + 1), max_rank, *signature)
    if capacity is None:
        capacity = len(payload)
    if (type(output_is_null) is not bool or type(capacity) is not int
            or capacity < 0 or output_is_null or capacity < len(payload)):
        return OUTPUT_ERROR_RESULT, b""
    return len(payload), payload
