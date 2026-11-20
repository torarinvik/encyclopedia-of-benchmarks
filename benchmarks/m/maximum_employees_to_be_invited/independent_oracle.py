"""Exhaustive subset and circular-order oracle, independent of graph peeling."""

from __future__ import annotations

from collections.abc import Sequence
from itertools import permutations

from .primary_oracle import (
    INVALID_RESULT,
    MAX_N,
    MAX_PARSEABLE_INPUT_LENGTH,
)


def _decode(values: Sequence[int] | None, input_length: int | None) -> list[int] | None:
    if not isinstance(values, (list, tuple)):
        return None
    if input_length is not None and (type(input_length) is not int or input_length != len(values)):
        return None
    if len(values) < 3 or len(values) > MAX_PARSEABLE_INPUT_LENGTH:
        return None
    if any(type(value) is not int or not -(1 << 63) <= value < (1 << 63) for value in values):
        return None
    n = values[0]
    if not 2 <= n <= MAX_N or len(values) != n + 1:
        return None
    favorite = list(values[1:])
    if any(not 0 <= favorite[i] < n or favorite[i] == i for i in range(n)):
        return None
    return favorite


def expected_result(values: Sequence[int] | None, input_length: int | None = None) -> int:
    favorite = _decode(values, input_length)
    if favorite is None:
        return INVALID_RESULT
    n = len(favorite)
    best = 0
    for mask in range(1, 1 << n):
        attendees = [person for person in range(n) if mask & (1 << person)]
        size = len(attendees)
        if size <= best:
            continue
        first = attendees[0]
        for suffix in permutations(attendees[1:]):
            order = (first, *suffix)
            valid = True
            for index, person in enumerate(order):
                previous = order[(index - 1) % size]
                following = order[(index + 1) % size]
                if favorite[person] != previous and favorite[person] != following:
                    valid = False
                    break
            if valid:
                best = size
                break
    return best


def expected_output(values: Sequence[int] | None, input_length: int | None = None) -> int:
    return expected_result(values, input_length)
