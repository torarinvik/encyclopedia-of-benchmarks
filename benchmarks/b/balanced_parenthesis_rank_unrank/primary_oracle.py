"""Completion-count DP for Dyck-word rank and unrank operations."""

from __future__ import annotations

I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1
MAX_PAIRS = 10
MAX_VALID_INPUT_LENGTH = 2 + 2 * MAX_PAIRS
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
WAYS_STRIDE = MAX_PAIRS + 1


def _decode(values, input_is_null=False, input_length=None):
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (tuple, list))
            or len(values) > MAX_PARSEABLE_INPUT_LENGTH
            or any(type(value) is not int or not I64_MIN <= value <= I64_MAX
                   for value in values)):
        return None
    if input_length is not None and (type(input_length) is not int or input_length != len(values)):
        return None
    if len(values) < 2 or values[1] < 1 or values[1] > MAX_PAIRS:
        return None
    mode, pairs = values[0], values[1]
    if mode == 0:
        if len(values) != 2 + 2 * pairs:
            return None
        symbols = tuple(values[2:])
        balance = 0
        for symbol in symbols:
            if symbol not in (0, 1):
                return None
            balance += 1 if symbol == 0 else -1
            if balance < 0:
                return None
        if balance != 0:
            return None
        return mode, pairs, symbols, None
    if mode == 1:
        if len(values) != 3:
            return None
        return mode, pairs, None, values[2]
    return None


def _completion_table(pairs):
    ways = [[0] * WAYS_STRIDE for _ in range(2 * pairs + 1)]
    ways[0][0] = 1
    for remaining in range(1, 2 * pairs + 1):
        for balance in range(pairs + 1):
            count = 0
            if balance < pairs:
                count += ways[remaining - 1][balance + 1]
            if balance > 0:
                count += ways[remaining - 1][balance - 1]
            ways[remaining][balance] = count
    return ways


def expected_result(values, input_is_null=False, input_length=None):
    decoded = _decode(values, input_is_null, input_length)
    if decoded is None:
        return -1
    mode, pairs, symbols, requested_rank = decoded
    ways = _completion_table(pairs)
    if mode == 0:
        rank = 0
        balance = 0
        length = 2 * pairs
        for index, symbol in enumerate(symbols):
            remaining = length - index - 1
            if symbol == 1 and balance < pairs:
                rank += ways[remaining][balance + 1]
            balance += 1 if symbol == 0 else -1
        return rank

    if requested_rank < 0 or requested_rank >= ways[2 * pairs][0]:
        return -1
    rank = requested_rank
    balance = 0
    code = 0
    length = 2 * pairs
    for index in range(length):
        remaining = length - index - 1
        open_count = ways[remaining][balance + 1] if balance < pairs else 0
        if rank < open_count:
            symbol = 0
            balance += 1
        else:
            rank -= open_count
            symbol = 1
            balance -= 1
        code = (code << 1) | symbol
    return code
