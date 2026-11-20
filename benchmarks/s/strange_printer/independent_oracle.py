"""Independent shortest-path search over complete printer tape states."""

from __future__ import annotations

from collections import deque
from collections.abc import Sequence

MAX_LENGTH = 8
MAX_SYMBOL = 2
MAX_PARSEABLE_INPUT_LENGTH = 10
INVALID_RESULT = -1
BLANK = 3
BASE = 4


def _parse(values: Sequence[int] | None, input_is_null: bool,
           input_length: int | None) -> tuple[int, ...] | None:
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple))
            or not 1 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
            or any(type(word) is not int or not -(1 << 63) <= word < (1 << 63)
                   for word in values)):
        return None
    if input_length is not None and (
            type(input_length) is not int or input_length != len(values)):
        return None
    n = values[0]
    if not 0 <= n <= MAX_LENGTH or len(values) != n + 1:
        return None
    target = tuple(values[1:])
    if any(symbol < 0 or symbol > MAX_SYMBOL for symbol in target):
        return None
    return target


def expected_result(values: Sequence[int] | None, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    target = _parse(values, input_is_null, input_length)
    if target is None:
        return INVALID_RESULT
    n = len(target)
    powers = [BASE ** position for position in range(n)]
    start = BLANK * sum(powers)
    goal = sum(symbol * powers[position] for position, symbol in enumerate(target))
    state_count = BASE ** n
    distance = [-1] * state_count
    distance[start] = 0
    queue = deque([start])

    while queue:
        state = queue.popleft()
        if state == goal:
            return distance[state]
        digits = [(state // powers[position]) % BASE for position in range(n)]
        for symbol in range(MAX_SYMBOL + 1):
            for left in range(n):
                next_state = state
                for right in range(left, n):
                    next_state += (symbol - digits[right]) * powers[right]
                    if distance[next_state] == -1:
                        distance[next_state] = distance[state] + 1
                        queue.append(next_state)
    return INVALID_RESULT
