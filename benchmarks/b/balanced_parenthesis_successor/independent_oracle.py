"""Exhaustive fixed-cardinality bit-string reference for Dyck successors."""

from __future__ import annotations

from itertools import combinations

I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1
MAX_PAIRS = 10
MAX_VALID_INPUT_LENGTH = 21
MAX_PARSEABLE_INPUT_LENGTH = 22
MAX_OUTPUT_BYTES = 20


def _decode(values, input_is_null, input_length):
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (tuple, list))
            or len(values) > MAX_PARSEABLE_INPUT_LENGTH
            or any(type(value) is not int or not I64_MIN <= value <= I64_MAX
                   for value in values)):
        return None
    if input_length is None:
        input_length = len(values)
    if type(input_length) is not int or input_length != len(values) or not values:
        return None
    pairs = values[0]
    if type(pairs) is not int or not 1 <= pairs <= MAX_PAIRS or len(values) != 1 + 2 * pairs:
        return None
    symbols = tuple(values[1:])
    depth = 0
    for symbol in symbols:
        if symbol not in (0, 1):
            return None
        depth += 1 if symbol == 0 else -1
        if depth < 0:
            return None
    if depth != 0:
        return None
    return pairs, symbols


def expected_output(values, output_capacity=None, output_is_null=False,
                    input_is_null=False, input_length=None):
    decoded = _decode(values, input_is_null, input_length)
    if decoded is None or type(output_is_null) is not bool:
        return -1, b""
    pairs, wanted = decoded
    length = 2 * pairs
    if (output_is_null or (output_capacity is not None
            and (type(output_capacity) is not int or output_capacity < length))):
        return -2, b""

    following = None
    for opening_positions in combinations(range(length), pairs):
        open_set = set(opening_positions)
        candidate = tuple(0 if index in open_set else 1 for index in range(length))
        depth = 0
        valid = True
        for symbol in candidate:
            depth += 1 if symbol == 0 else -1
            if depth < 0:
                valid = False
                break
        if valid and depth == 0:
            if following is not None:
                if following == wanted:
                    return length, bytes(40 if symbol == 0 else 41 for symbol in candidate)
                following = candidate
            elif candidate == wanted:
                following = candidate
    return -3, b""


def expected_result(values, output_capacity=None, output_is_null=False,
                    input_is_null=False, input_length=None):
    return expected_output(values, output_capacity, output_is_null,
                          input_is_null, input_length)[0]
