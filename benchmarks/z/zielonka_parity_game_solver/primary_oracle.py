"""Zielonka recursive solver for the bounded minimum-priority game profile."""

from __future__ import annotations

from collections.abc import Sequence

MAX_VERTICES = 8
MAX_EDGES = 20
MAX_PRIORITY = 5
MAX_VALID_INPUT_LENGTH = 58
MAX_PARSEABLE_INPUT_LENGTH = 59


def parse_frame(values: Sequence[int]) -> dict | None:
    if not isinstance(values, Sequence) or len(values) < 6 or len(values) > MAX_PARSEABLE_INPUT_LENGTH:
        return None
    if any(type(value) is not int for value in values):
        return None
    vertex_count, edge_count = values[:2]
    if not 1 <= vertex_count <= MAX_VERTICES or not vertex_count <= edge_count <= MAX_EDGES:
        return None
    if len(values) != 2 + 2 * vertex_count + 2 * edge_count:
        return None
    owners: list[int] = []
    priorities: list[int] = []
    offset = 2
    for _ in range(vertex_count):
        owner, priority = values[offset:offset + 2]
        offset += 2
        if owner not in (0, 1) or not 0 <= priority <= MAX_PRIORITY:
            return None
        owners.append(owner)
        priorities.append(priority)
    adjacency = [0] * vertex_count
    outdegree = [0] * vertex_count
    for _ in range(edge_count):
        source, destination = values[offset:offset + 2]
        offset += 2
        if not 0 <= source < vertex_count or not 0 <= destination < vertex_count:
            return None
        bit = 1 << destination
        if adjacency[source] & bit:
            return None
        adjacency[source] |= bit
        outdegree[source] += 1
    if any(degree == 0 for degree in outdegree):
        return None
    return {"vertex_count": vertex_count, "owners": owners,
            "priorities": priorities, "adjacency": adjacency}


def _attractor(active: int, player: int, target: int,
               owners: list[int], adjacency: list[int], vertex_count: int) -> int:
    attracted = target
    while True:
        additions = 0
        for vertex in range(vertex_count):
            bit = 1 << vertex
            if not active & bit or attracted & bit:
                continue
            successors = adjacency[vertex] & active
            if owners[vertex] == player:
                if successors & attracted:
                    additions |= bit
            elif successors and successors & ~attracted == 0:
                additions |= bit
        if additions == 0:
            return attracted
        attracted |= additions


def expected_result(values: Sequence[int]) -> int:
    frame = parse_frame(values)
    if frame is None:
        return -1
    vertex_count = frame["vertex_count"]
    owners = frame["owners"]
    priorities = frame["priorities"]
    adjacency = frame["adjacency"]

    def solve(active: int) -> int:
        if active == 0:
            return 0
        lowest = min(priorities[v] for v in range(vertex_count) if active & (1 << v))
        player = lowest & 1
        target = sum(1 << v for v in range(vertex_count)
                     if active & (1 << v) and priorities[v] == lowest)
        first_attractor = _attractor(active, player, target, owners, adjacency, vertex_count)
        remainder = active & ~first_attractor
        even_after_first = solve(remainder)
        odd_after_first = remainder & ~even_after_first
        opponent_region = even_after_first if player == 1 else odd_after_first
        if opponent_region == 0:
            return even_after_first | (first_attractor if player == 0 else 0)

        second_attractor = _attractor(
            active, 1 - player, opponent_region, owners, adjacency, vertex_count)
        even_after_second = solve(active & ~second_attractor)
        return even_after_second | (second_attractor if player == 1 else 0)

    return solve((1 << vertex_count) - 1)
