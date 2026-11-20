"""Simultaneous-cycle Top Trading Cycles for a bounded housing market."""

from __future__ import annotations

from collections.abc import Sequence

MAX_AGENTS = 8
MAX_VALID_INPUT_LENGTH = 1 + MAX_AGENTS * MAX_AGENTS
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_INPUT_LENGTH = MAX_PARSEABLE_INPUT_LENGTH
MAX_RESULT = 1 << 24


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
    preferences: list[list[int]] = []
    offset = 1
    for _agent in range(count):
        row = list(values[offset:offset + count])
        if set(row) != set(range(count)):
            return None
        preferences.append(row)
        offset += count
    return count, preferences


def _encode(allocation: Sequence[int]) -> int:
    return 1 + sum(house << (3 * agent) for agent, house in enumerate(allocation))


def expected_result(values: Sequence[int] | None, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    parsed = _parse(values, input_is_null, input_length)
    if parsed is None:
        return -1
    count, preferences = parsed
    active = [True] * count
    remaining = count
    allocation = [-1] * count

    while remaining:
        choice = [-1] * count
        for agent in range(count):
            if active[agent]:
                choice[agent] = next(house for house in preferences[agent] if active[house])

        state = [0] * count
        path_position = [-1] * count
        cycles: list[list[int]] = []
        for root in range(count):
            if not active[root] or state[root] != 0:
                continue
            path: list[int] = []
            vertex = root
            while active[vertex] and state[vertex] == 0:
                state[vertex] = 1
                path_position[vertex] = len(path)
                path.append(vertex)
                vertex = choice[vertex]
            if state[vertex] == 1 and path_position[vertex] >= 0:
                cycles.append(path[path_position[vertex]:])
            for member in path:
                state[member] = 2
                path_position[member] = -1

        if not cycles:
            return -1
        for cycle in cycles:
            for agent in cycle:
                allocation[agent] = choice[agent]
                active[agent] = False
                remaining -= 1

    if sorted(allocation) != list(range(count)):
        return -1
    return _encode(allocation)
