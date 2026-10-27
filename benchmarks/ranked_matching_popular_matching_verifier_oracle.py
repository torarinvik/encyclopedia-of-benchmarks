"""Independent DOI 331 verifier using recursive assignment search and closure."""

from __future__ import annotations

import struct
from collections.abc import Sequence

LIMIT = 51


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or capacity is not None and (type(capacity) is not int or capacity < 0)
            or input_length is not None and (type(input_length) is not int or not 0 <= input_length <= LIMIT)
            or input_is_null and values not in (None, [], ())
            or not input_is_null and values is not None and input_length is not None and input_length != len(values)):
        return -1, b""
    if input_is_null or values is None or not isinstance(values, (list, tuple)):
        return -1, b""
    if not 6 <= len(values) <= LIMIT or any(type(x) is not int or not -(1 << 63) <= x < (1 << 63) for x in values):
        return -1, b""
    applicants, posts, edge_count = values[:3]
    if not 1 <= applicants <= 4 or not 1 <= posts <= 4 or not applicants <= edge_count <= applicants * posts or len(values) != 3 + 3 * edge_count:
        return -1, b""
    preference = [[0 for _ in range(posts)] for _ in range(applicants)]
    rank_sets = [set() for _ in range(applicants)]
    for offset in range(3, len(values), 3):
        a, p, rank = values[offset:offset + 3]
        if not 0 <= a < applicants or not 0 <= p < posts or not 1 <= rank <= posts or preference[a][p] != 0:
            return -1, b""
        preference[a][p] = rank
        rank_sets[a].add(rank)
    if any(not ranks or ranks != set(range(1, max(ranks) + 1)) for ranks in rank_sets):
        return -1, b""

    # Enumerate all partial matchings of the rank-one graph recursively.
    rank_one_best = -1
    rank_one_match: tuple[int, ...] | None = None
    partial: list[int] = []

    def visit_first(a: int, occupied: frozenset[int], count: int) -> None:
        nonlocal rank_one_best, rank_one_match
        if a == applicants:
            candidate = tuple(partial)
            if count > rank_one_best or (count == rank_one_best and (rank_one_match is None or candidate < rank_one_match)):
                rank_one_best, rank_one_match = count, candidate
            return
        # The sentinel sorts after every real post.
        for p in range(posts + 1):
            if p == posts:
                partial.append(posts)
                visit_first(a + 1, occupied, count)
                partial.pop()
            elif preference[a][p] == 1 and p not in occupied:
                partial.append(p)
                visit_first(a + 1, occupied | {p}, count + 1)
                partial.pop()

    visit_first(0, frozenset(), 0)
    assert rank_one_match is not None
    mate_a = [-1] * applicants
    mate_p = [-1] * posts
    for a, p in enumerate(rank_one_match):
        if p < posts:
            mate_a[a], mate_p[p] = p, a

    total_posts = posts + applicants
    total_nodes = applicants + total_posts
    # Independent fixed-point closure for alternating even/odd reachability.
    even: set[int] = {a for a in range(applicants) if mate_a[a] < 0}
    even.update(applicants + p for p in range(posts) if mate_p[p] < 0)
    even.update(applicants + p for p in range(posts, total_posts))
    odd: set[int] = set()
    changed = True
    while changed:
        changed = False
        for a in range(applicants):
            if a in even:
                for p in range(posts):
                    node = applicants + p
                    if preference[a][p] == 1 and mate_a[a] != p and node not in odd and node not in even:
                        odd.add(node)
                        changed = True
            if a in odd and mate_a[a] >= 0:
                node = applicants + mate_a[a]
                if node not in even and node not in odd:
                    even.add(node)
                    changed = True
        for p in range(posts):
            node = applicants + p
            if node in even:
                for a in range(applicants):
                    if preference[a][p] == 1 and mate_a[a] != p and a not in odd and a not in even:
                        odd.add(a)
                        changed = True
            if node in odd and mate_p[p] >= 0:
                target = mate_p[p]
                if target not in even and target not in odd:
                    even.add(target)
                    changed = True

    def kind(node: int) -> int:
        return 0 if node in even else (1 if node in odd else 2)

    reduced = [[False] * total_posts for _ in range(applicants)]
    for a in range(applicants):
        max_rank = max(preference[a])
        last_rank = max_rank + 1
        even_ranks = [preference[a][p] for p in range(posts)
                      if preference[a][p] and kind(applicants + p) == 0]
        if kind(applicants + posts + a) == 0:
            even_ranks.append(last_rank)
        selected_rank = min(even_ranks)
        for p in range(posts):
            if preference[a][p] == 1 or (preference[a][p] == selected_rank and kind(applicants + p) == 0):
                reduced[a][p] = True
        if selected_rank == last_rank and kind(applicants + posts + a) == 0:
            reduced[a][posts + a] = True

    graph: list[list[int]] = [[] for _ in range(applicants)]
    for a in range(applicants):
        for p in range(total_posts):
            if not reduced[a][p]:
                continue
            ca, cp = kind(a), kind(applicants + p)
            if (ca == 1 and cp in (1, 2)) or (ca == 2 and cp == 1):
                continue
            graph[a].append(p)

    winner: tuple[int, ...] | None = None
    partial.clear()

    def visit_full(a: int, occupied: frozenset[int], first_count: int) -> None:
        nonlocal winner
        if a == applicants:
            candidate = tuple(partial)
            if first_count == rank_one_best and (winner is None or candidate < winner):
                winner = candidate
            return
        for p in graph[a]:
            if p in occupied:
                continue
            partial.append(p)
            visit_full(a + 1, occupied | {p}, first_count + int(p < posts and preference[a][p] == 1))
            partial.pop()

    visit_full(0, frozenset(), 0)
    fields = [0, *([-1] * applicants)] if winner is None else [1, *winner]
    payload = b"".join(struct.pack("<q", field) for field in fields)
    if output_is_null or capacity is not None and capacity < len(payload):
        return -2, b""
    return len(payload), payload
