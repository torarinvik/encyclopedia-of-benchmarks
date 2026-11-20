"""Linear monotone-deque reference for the bounded shortest-subarray profile."""

from __future__ import annotations

from collections.abc import Sequence

MIN_TARGET = -4096
MAX_TARGET = 4096
MAX_COUNT = 256
MIN_VALUE = -1000
MAX_VALUE = 1000
MAX_VALID_INPUT_LENGTH = 258
MAX_PARSEABLE_INPUT_LENGTH = 259
MAX_INPUT_LENGTH = MAX_PARSEABLE_INPUT_LENGTH
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1


def _decode(
    values: Sequence[int] | None,
    input_length: int | None,
    input_is_null: bool,
) -> tuple[int, list[int]] | None:
    if (
        type(input_is_null) is not bool
        or input_is_null
        or not isinstance(values, (list, tuple))
        or not 2 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
        or any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values)
    ):
        return None
    if input_length is not None and (
        type(input_length) is not int or input_length != len(values)
    ):
        return None
    target, count = values[0], values[1]
    if not MIN_TARGET <= target <= MAX_TARGET or not 0 <= count <= MAX_COUNT:
        return None
    if len(values) != count + 2:
        return None
    sequence = list(values[2:])
    if any(not MIN_VALUE <= value <= MAX_VALUE for value in sequence):
        return None
    return target, sequence


def expected_output(
    values: Sequence[int] | None,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> int:
    decoded = _decode(values, input_length, input_is_null)
    if decoded is None:
        return -1
    target, sequence = decoded
    count = len(sequence)
    prefix = [0] * (count + 1)
    for index, value in enumerate(sequence):
        prefix[index + 1] = prefix[index] + value

    deque = [0] * (count + 1)
    head = 0
    tail = 0
    best = count + 1
    for right in range(count + 1):
        while head < tail and prefix[right] - prefix[deque[head]] >= target:
            best = min(best, right - deque[head])
            head += 1
        while head < tail and prefix[right] <= prefix[deque[tail - 1]]:
            tail -= 1
        deque[tail] = right
        tail += 1
    return best if best <= count else 0
