"""Bounded DOI 331 ranked-popular-matching oracle."""

from __future__ import annotations

import struct
from collections.abc import Sequence

MAX_INPUT = 51
MAX_OUTPUT = 40
MAX_A = 4
MAX_P = 4


def _parse(values: Sequence[int] | None) -> tuple[int, int, list[list[int]]] | None:
    if values is None or not isinstance(values, (list, tuple)):
        return None
    if len(values) < 6 or len(values) > MAX_INPUT:
        return None
    if any(type(value) is not int or not -(1 << 63) <= value < (1 << 63) for value in values):
        return None
    a_count, p_count, edge_count = values[:3]
    if not 1 <= a_count <= MAX_A or not 1 <= p_count <= MAX_P:
        return None
    if not a_count <= edge_count <= a_count * p_count or len(values) != 3 + 3 * edge_count:
        return None
    ranks = [[0] * MAX_P for _ in range(MAX_A)]
    max_rank = [0] * MAX_A
    cursor = 3
    for _ in range(edge_count):
        applicant, post, rank = values[cursor:cursor + 3]
        cursor += 3
        if not (0 <= applicant < a_count and 0 <= post < p_count and 1 <= rank <= p_count):
            return None
        if ranks[applicant][post] != 0:
            return None
        ranks[applicant][post] = rank
        max_rank[applicant] = max(max_rank[applicant], rank)
    for applicant in range(a_count):
        present = {rank for rank in ranks[applicant][:p_count] if rank > 0}
        if not present or present != set(range(1, max_rank[applicant] + 1)):
            return None
    return a_count, p_count, ranks


def _rank_one_maximum(a_count: int, p_count: int, ranks: list[list[int]]) -> tuple[int, list[int]]:
    best_size = -1
    best_assignment: tuple[int, ...] | None = None
    combinations = (p_count + 1) ** a_count
    for code in range(combinations):
        value = code
        assignment: list[int] = []
        used = 0
        count = 0
        valid = True
        for applicant in range(a_count):
            choice = value % (p_count + 1)
            value //= p_count + 1
            assignment.append(choice)
            if choice == p_count:
                continue
            if ranks[applicant][choice] != 1 or (used & (1 << choice)):
                valid = False
                break
            used |= 1 << choice
            count += 1
        if valid and (count > best_size or (count == best_size and (best_assignment is None or tuple(assignment) < best_assignment))):
            best_size = count
            best_assignment = tuple(assignment)
    assert best_assignment is not None
    return best_size, list(best_assignment)


def _solve(a_count: int, p_count: int, ranks: list[list[int]]) -> list[int] | None:
    rank_one_size, rank_one_assignment = _rank_one_maximum(a_count, p_count, ranks)
    post_count = p_count + a_count
    node_count = a_count + post_count
    matched_post = [-1] * p_count
    matched_applicant = [-1] * a_count
    for applicant, post in enumerate(rank_one_assignment):
        if post < p_count:
            matched_applicant[applicant] = post
            matched_post[post] = applicant

    # Gallai–Edmonds E/O/U classes via an alternating forest rooted at every
    # exposed vertex of the rank-one graph, including isolated last resorts.
    parity = [-1] * node_count
    queue: list[int] = []
    for applicant in range(a_count):
        if matched_applicant[applicant] < 0:
            parity[applicant] = 0
            queue.append(applicant)
    for post in range(p_count):
        if matched_post[post] < 0:
            node = a_count + post
            parity[node] = 0
            queue.append(node)
    for post in range(p_count, post_count):
        node = a_count + post
        parity[node] = 0
        queue.append(node)
    cursor = 0
    while cursor < len(queue):
        node = queue[cursor]
        cursor += 1
        if node < a_count:
            applicant = node
            if parity[node] == 0:
                for post in range(p_count):
                    if ranks[applicant][post] == 1 and matched_applicant[applicant] != post:
                        target = a_count + post
                        if parity[target] < 0:
                            parity[target] = 1
                            queue.append(target)
            elif matched_applicant[applicant] >= 0:
                target = a_count + matched_applicant[applicant]
                if parity[target] < 0:
                    parity[target] = 0
                    queue.append(target)
        else:
            post = node - a_count
            if post < p_count:
                if parity[node] == 0:
                    for applicant in range(a_count):
                        if ranks[applicant][post] == 1 and matched_applicant[applicant] != post:
                            if parity[applicant] < 0:
                                parity[applicant] = 1
                                queue.append(applicant)
                elif matched_post[post] >= 0:
                    target = matched_post[post]
                    if parity[target] < 0:
                        parity[target] = 0
                        queue.append(target)

    # Class values are even=0, odd=1, unreachable=2.
    classes = [value if value >= 0 else 2 for value in parity]
    reduced = [[False] * post_count for _ in range(a_count)]
    for applicant in range(a_count):
        first_posts = [post for post in range(p_count) if ranks[applicant][post] == 1]
        best_even_rank = p_count + 1
        for post in range(p_count):
            if ranks[applicant][post] > 0 and classes[a_count + post] == 0:
                best_even_rank = min(best_even_rank, ranks[applicant][post])
        last_rank = max(rank for rank in ranks[applicant][:p_count] if rank > 0) + 1
        if classes[a_count + p_count + applicant] == 0:
            best_even_rank = min(best_even_rank, last_rank)
        for post in first_posts:
            reduced[applicant][post] = True
        for post in range(p_count):
            if ranks[applicant][post] > 0 and ranks[applicant][post] == best_even_rank and classes[a_count + post] == 0:
                reduced[applicant][post] = True
        if last_rank == best_even_rank and classes[a_count + p_count + applicant] == 0:
            reduced[applicant][p_count + applicant] = True

    allowed = [[False] * post_count for _ in range(a_count)]
    for applicant in range(a_count):
        for post in range(post_count):
            if not reduced[applicant][post]:
                continue
            applicant_class = classes[applicant]
            post_class = classes[a_count + post]
            if applicant_class == 1 and post_class in (1, 2):
                continue
            if applicant_class == 2 and post_class == 1:
                continue
            allowed[applicant][post] = True

    best: tuple[int, ...] | None = None
    combinations = post_count ** a_count
    for code in range(combinations):
        value = code
        assignment: list[int] = []
        used = 0
        rank_one_count = 0
        valid = True
        for applicant in range(a_count):
            post = value % post_count
            value //= post_count
            assignment.append(post)
            if not allowed[applicant][post] or (used & (1 << post)):
                valid = False
                break
            used |= 1 << post
            if post < p_count and ranks[applicant][post] == 1:
                rank_one_count += 1
        if valid and rank_one_count == rank_one_size:
            candidate = tuple(assignment)
            if best is None or candidate < best:
                best = candidate
    return list(best) if best is not None else None


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or capacity is not None and (type(capacity) is not int or capacity < 0)
            or input_length is not None and (type(input_length) is not int or not 0 <= input_length <= MAX_INPUT)
            or input_is_null and values not in (None, [], ())
            or not input_is_null and values is not None and input_length is not None and input_length != len(values)):
        return -1, b""
    if input_is_null or values is None:
        return -1, b""
    parsed = _parse(values)
    if parsed is None:
        return -1, b""
    a_count, p_count, ranks = parsed
    assignment = _solve(a_count, p_count, ranks)
    fields = [0, *([-1] * a_count)] if assignment is None else [1, *assignment]
    payload = b"".join(struct.pack("<q", field) for field in fields)
    if output_is_null or capacity is not None and capacity < len(payload):
        return -2, b""
    return len(payload), payload
