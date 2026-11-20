"""Rightmost-flippable-symbol successor for bounded Dyck words."""

from __future__ import annotations

I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1
MAX_PAIRS = 10
MAX_VALID_INPUT_LENGTH = 1 + 2 * MAX_PAIRS
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_OUTPUT_BYTES = 2 * MAX_PAIRS


def _decode(values, input_is_null=False, input_length=None):
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (tuple, list))
            or len(values) > MAX_PARSEABLE_INPUT_LENGTH
            or any(type(value) is not int or not I64_MIN <= value <= I64_MAX
                   for value in values)):
        return None
    if input_length is not None and (type(input_length) is not int or input_length != len(values)):
        return None
    if not values or not 1 <= values[0] <= MAX_PAIRS:
        return None
    pairs = values[0]
    if len(values) != 1 + 2 * pairs:
        return None
    symbols = list(values[1:])
    balance = 0
    for symbol in symbols:
        if symbol not in (0, 1):
            return None
        balance += 1 if symbol == 0 else -1
        if balance < 0:
            return None
    if balance != 0:
        return None
    return pairs, symbols


def expected_output(values, output_capacity=None, output_is_null=False,
                    input_is_null=False, input_length=None):
    decoded = _decode(values, input_is_null, input_length)
    if decoded is None or type(output_is_null) is not bool:
        return -1, b""
    pairs, symbols = decoded
    required = 2 * pairs
    if (output_is_null or (output_capacity is not None
            and (type(output_capacity) is not int or output_capacity < required))):
        return -2, b""

    depth = 0
    for index in range(required - 1, -1, -1):
        if symbols[index] == 0:
            depth -= 1
        else:
            depth += 1
        if symbols[index] == 0 and depth > 0:
            depth -= 1
            suffix_length = required - index - 1
            opening_count = (suffix_length - depth) // 2
            closing_count = suffix_length - opening_count
            result = symbols[:index] + [1] + [0] * opening_count + [1] * closing_count
            return required, bytes(40 if symbol == 0 else 41 for symbol in result)
    return -3, b""


def expected_result(values, output_capacity=None, output_is_null=False,
                    input_is_null=False, input_length=None):
    return expected_output(values, output_capacity, output_is_null,
                          input_is_null, input_length)[0]
