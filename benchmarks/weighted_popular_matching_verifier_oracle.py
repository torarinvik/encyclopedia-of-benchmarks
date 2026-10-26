"""Independent verifier enumerating item choices recursively by applicant."""

from __future__ import annotations

import struct
from collections.abc import Sequence

MAX_INPUT = 22


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or capacity is not None and (type(capacity) is not int or capacity < 0)
            or input_length is not None and (type(input_length) is not int or not 0 <= input_length <= MAX_INPUT)
            or input_is_null and values not in (None, [], ())
            or not input_is_null and values is not None and input_length is not None and input_length != len(values)):
        return -1, b""
    if input_is_null or values is None or not isinstance(values, (list, tuple)):
        return -1, b""
    if len(values) < 4 or len(values) > MAX_INPUT or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63) for value in values):
        return -1, b""
    people, items = values[0], values[1]
    if not 1 <= people <= 4 or not 1 <= items <= 4 or len(values) != 2 + people + people * items:
        return -1, b""
    importance = tuple(values[2:2 + people])
    preferences = tuple(tuple(values[2 + people + i * items:2 + people + (i + 1) * items]) for i in range(people))
    if any(not 1 <= weight <= 1000 for weight in importance) or any(sorted(row) != list(range(items)) for row in preferences):
        return -1, b""

    options: list[tuple[int, ...]] = []

    def enumerate_assignments(person: int, taken: frozenset[int], current: tuple[int, ...]) -> None:
        if person == people:
            options.append(current)
            return
        enumerate_assignments(person + 1, taken, current + (-1,))
        for item in range(items):
            if item not in taken:
                enumerate_assignments(person + 1, taken | {item}, current + (item,))

    enumerate_assignments(0, frozenset(), ())
    winner: tuple[int, ...] | None = None
    winner_size = -1
    for proposed in options:
        beaten = False
        for challenge in options:
            margin = 0
            for person in range(people):
                proposed_rank = items if proposed[person] == -1 else preferences[person][proposed[person]]
                challenge_rank = items if challenge[person] == -1 else preferences[person][challenge[person]]
                margin += importance[person] * ((proposed_rank > challenge_rank) - (proposed_rank < challenge_rank))
            if margin > 0:
                beaten = True
                break
        if not beaten:
            size = sum(item != -1 for item in proposed)
            if size > winner_size or size == winner_size and (winner is None or proposed < winner):
                winner = proposed
                winner_size = size
    fields = [0, 0, *([-1] * people)] if winner is None else [1, winner_size, *winner]
    payload = b"".join(struct.pack("<q", field) for field in fields)
    if output_is_null or capacity is not None and capacity < len(payload):
        return -2, b""
    return len(payload), payload
