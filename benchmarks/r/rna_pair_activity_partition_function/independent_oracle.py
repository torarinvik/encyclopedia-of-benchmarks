"""Left-endpoint decomposition reference for the RNA pair partition function."""

from functools import lru_cache

MAX_LENGTH = 16
MAX_PARSEABLE_INPUT_LENGTH = 122
MAX_VALID_INPUT_LENGTH = 121
MAX_ACTIVITY = 3
WORKSPACE_BYTES = 2048


def _is_i64(value: object) -> bool:
    return type(value) is int and -(1 << 63) <= value < (1 << 63)


def _pair_input_index(length: int, left: int, right: int) -> int:
    return 1 + left * (2 * length - left - 1) // 2 + (right - left - 1)


def expected_result(values: object, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    if type(input_is_null) is not bool:
        return -1
    if input_length is not None and (type(input_length) is not int or input_length < 0):
        return -1
    if input_is_null or not isinstance(values, (list, tuple)):
        return -1
    size = len(values)
    if not 1 <= size <= MAX_PARSEABLE_INPUT_LENGTH:
        return -1
    if input_length is not None and input_length != size:
        return -1
    if any(not _is_i64(value) for value in values):
        return -1

    length = values[0]
    if not 0 <= length <= MAX_LENGTH:
        return -1
    if size != 1 + length * (length - 1) // 2:
        return -1
    if any(not 0 <= activity <= MAX_ACTIVITY for activity in values[1:]):
        return -1

    @lru_cache(maxsize=None)
    def structures(left: int, right: int) -> int:
        if left > right:
            return 1
        total = structures(left + 1, right)
        for partner in range(left + 1, right + 1):
            activity = values[_pair_input_index(length, left, partner)]
            total += (activity * structures(left + 1, partner - 1)
                      * structures(partner + 1, right))
        return total

    return structures(0, length - 1)
