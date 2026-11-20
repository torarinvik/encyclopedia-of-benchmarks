"""Direct repeated-deck simulation for perfect out-shuffle order."""

from __future__ import annotations

MAX_DECK_SIZE = 10000
MAX_VALID_INPUT_LENGTH = 1
MAX_PARSEABLE_INPUT_LENGTH = 2
WORKSPACE_BYTES = 196608


def _decode(values, input_is_null: bool, input_length: int | None):
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple))
            or len(values) > MAX_PARSEABLE_INPUT_LENGTH
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return None
    if input_length is not None and (
            type(input_length) is not int or input_length != len(values)):
        return None
    if len(values) != 1:
        return None
    deck_size = values[0]
    if not 2 <= deck_size <= MAX_DECK_SIZE or deck_size % 2 != 0:
        return None
    return deck_size


def expected_result(values, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    deck_size = _decode(values, input_is_null, input_length)
    if deck_size is None:
        return -1
    current = list(range(deck_size))
    following = [0] * deck_size
    count = 0
    while True:
        half = deck_size // 2
        for index in range(half):
            following[2 * index] = current[index]
            following[2 * index + 1] = current[half + index]
        count += 1
        if all(following[index] == index for index in range(deck_size)):
            return count
        current, following = following, current
