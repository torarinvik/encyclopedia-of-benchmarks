"""Single-cycle Floyd traversal plus a direct core-stability check for TTC."""

from __future__ import annotations

from collections.abc import Sequence

from .primary_oracle import MAX_AGENTS, MAX_PARSEABLE_INPUT_LENGTH
from .primary_oracle import _encode


def _parse(values: Sequence[int] | None, input_is_null: bool = False,
           input_length: int | None = None) -> tuple[int, list[list[int]]] | None:
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple))
            or not 2 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)
            or input_length is not None
            and (type(input_length) is not int or input_length != len(values))):
        return None
    count = values[0]
    if not 1 <= count <= MAX_AGENTS or len(values) != 1 + count * count:
        return None
    rows = [list(values[1 + agent * count:1 + (agent + 1) * count])
            for agent in range(count)]
    expected = set(range(count))
    if any(set(row) != expected for row in rows):
        return None
    return count, rows


def _is_core(allocation: Sequence[int], preferences: Sequence[Sequence[int]]) -> bool:
    count = len(allocation)
    ranks = [[0] * count for _ in range(count)]
    for agent, row in enumerate(preferences):
        for rank, house in enumerate(row):
            ranks[agent][house] = rank

    for coalition in range(1, 1 << count):
        members = [agent for agent in range(count) if coalition & (1 << agent)]
        eligible = {
            agent: [house for house in members
                    if ranks[agent][house] < ranks[agent][allocation[agent]]]
            for agent in members
        }
        if any(not eligible[agent] for agent in members):
            continue
        members.sort(key=lambda agent: (len(eligible[agent]), agent))

        def can_reassign(position: int, used_houses: int) -> bool:
            if position == len(members):
                return True
            agent = members[position]
            for house in eligible[agent]:
                bit = 1 << house
                if not used_houses & bit and can_reassign(position + 1, used_houses | bit):
                    return True
            return False

        if can_reassign(0, 0):
            return False
    return True


def expected_result(values: Sequence[int] | None, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    parsed = _parse(values, input_is_null, input_length)
    if parsed is None:
        return -1
    count, preferences = parsed
    active = [True] * count
    allocation = [-1] * count
    remaining = count

    while remaining:
        start = next(agent for agent in range(count) if active[agent])
        successor = [-1] * count
        for agent in range(count):
            if active[agent]:
                successor[agent] = next(house for house in preferences[agent] if active[house])

        slow = successor[start]
        fast = successor[successor[start]]
        while slow != fast:
            slow = successor[slow]
            fast = successor[successor[fast]]
        slow = start
        while slow != fast:
            slow = successor[slow]
            fast = successor[fast]
        cycle_start = slow
        cycle = [cycle_start]
        vertex = successor[cycle_start]
        while vertex != cycle_start:
            cycle.append(vertex)
            vertex = successor[vertex]

        for agent in cycle:
            allocation[agent] = successor[agent]
            active[agent] = False
            remaining -= 1

    if sorted(allocation) != list(range(count)) or not _is_core(allocation, preferences):
        raise ValueError("single-cycle TTC result is not the unique housing-market core")
    return _encode(allocation)
