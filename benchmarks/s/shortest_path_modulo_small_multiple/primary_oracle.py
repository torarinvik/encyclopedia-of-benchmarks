"""0-1 BFS for the least digit sum of a decimal 0/1 multiple."""

from __future__ import annotations

from collections import deque
from collections.abc import Sequence

MAX_N = 16
MAX_VALID_INPUT_LENGTH = 1
MAX_PARSEABLE_INPUT_LENGTH = 2
INVALID_RESULT = -1


def _parse(values: Sequence[int] | None, input_is_null: bool,
           input_length: int | None) -> int | None:
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple))
            or len(values) > MAX_PARSEABLE_INPUT_LENGTH
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return None
    if input_length is not None and (
            type(input_length) is not int or input_length != len(values)):
        return None
    if len(values) != 1 or not 1 <= values[0] <= MAX_N:
        return None
    return values[0]


def expected_result(values: Sequence[int] | None, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    n = _parse(values, input_is_null, input_length)
    if n is None:
        return INVALID_RESULT

    distance = [MAX_N + 1] * n
    start = 1 % n
    distance[start] = 1
    queue = deque([start])
    while queue:
        residue = queue.popleft()
        zero_next = (10 * residue) % n
        if distance[zero_next] > distance[residue]:
            distance[zero_next] = distance[residue]
            queue.appendleft(zero_next)
        one_next = (zero_next + 1) % n
        if distance[one_next] > distance[residue] + 1:
            distance[one_next] = distance[residue] + 1
            queue.append(one_next)
    return distance[0]
