"""Primary array-linked implementation of Pritchard's dynamic wheel sieve."""

from __future__ import annotations

from collections.abc import Sequence

INVALID_RESULT = -1
MIN_LIMIT = 2
MAX_LIMIT = 1024
MAX_VALID_INPUT_LENGTH = 1
MAX_PARSEABLE_INPUT_LENGTH = 2
MAX_WORKSPACE_BYTES = 9216


def _decode(values: Sequence[int] | None, input_is_null: bool,
            input_length: int | None) -> int | None:
    if type(input_is_null) is not bool or input_is_null:
        return None
    if not isinstance(values, (list, tuple)):
        return None
    length = len(values) if input_length is None else input_length
    if (type(length) is not int or length != len(values)
            or not 1 <= length <= MAX_PARSEABLE_INPUT_LENGTH
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return None
    if length != 1 or not MIN_LIMIT <= values[0] <= MAX_LIMIT:
        return None
    return values[0]


def _extend(next_node: list[int], previous: list[int], length: int,
            target: int, sentinel: int) -> int:
    wheel_value = 1
    candidate = length + 1
    while candidate <= target:
        tail = previous[sentinel]
        next_node[tail] = candidate
        previous[candidate] = tail
        next_node[candidate] = sentinel
        previous[sentinel] = candidate
        wheel_value = next_node[wheel_value]
        candidate = length + wheel_value
    return target


def _delete_multiples(next_node: list[int], previous: list[int], prime: int,
                      length: int) -> None:
    wheel_value = prime
    while prime * wheel_value <= length:
        wheel_value = next_node[wheel_value]
    while wheel_value > 1:
        wheel_value = previous[wheel_value]
        removed = prime * wheel_value
        left = previous[removed]
        right = next_node[removed]
        next_node[left] = right
        previous[right] = left


def _pritchard_count(limit: int) -> int:
    sentinel = limit + 1
    next_node = [0] * (MAX_LIMIT + 2)
    previous = [0] * (MAX_LIMIT + 2)
    next_node[1] = sentinel
    next_node[sentinel] = sentinel
    previous[sentinel] = 1
    length = 2
    prime = 3
    prime_count = 1  # prime 2 is already in the emitted-prime count

    while prime * prime <= limit:
        if length < limit:
            target = min(prime * length, limit)
            length = _extend(next_node, previous, length, target, sentinel)
        _delete_multiples(next_node, previous, prime, length)
        prime_count += 1
        prime = next_node[1]

    if length < limit:
        length = _extend(next_node, previous, length, limit, sentinel)

    remaining = 0
    value = next_node[1]
    while value != sentinel:
        remaining += 1
        value = next_node[value]
    return prime_count + remaining


def expected_result(values: Sequence[int] | None,
                    input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    limit = _decode(values, input_is_null, input_length)
    return INVALID_RESULT if limit is None else _pritchard_count(limit)
