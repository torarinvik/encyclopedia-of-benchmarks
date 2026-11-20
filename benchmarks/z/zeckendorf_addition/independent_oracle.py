"""Decode-and-greedy-encode reference, independent of the three-pass normalizer."""

from __future__ import annotations

from collections.abc import Sequence

from .primary_oracle import I64_MAX, I64_MIN, MAX_BITS, MAX_PARSEABLE_INPUT_LENGTH


def _valid_bits(bits: list[int]) -> bool:
    if not bits or any(bit not in (0, 1) for bit in bits):
        return False
    if len(bits) == 1 and bits[0] == 0:
        return True
    return bits[0] == 1 and all(
        bits[index] + bits[index + 1] <= 1 for index in range(len(bits) - 1)
    )


def _parse(values: Sequence[int]) -> tuple[list[int], list[int]] | None:
    if len(values) < 4 or len(values) > MAX_PARSEABLE_INPUT_LENGTH:
        return None
    first_length = values[0]
    if first_length < 1 or first_length > MAX_BITS:
        return None
    second_length_index = first_length + 1
    if second_length_index >= len(values):
        return None
    second_length = values[second_length_index]
    if second_length < 1 or second_length > MAX_BITS:
        return None
    if len(values) != second_length_index + second_length + 1:
        return None
    first = values[1:second_length_index]
    second = values[second_length_index + 1:]
    if not _valid_bits(first) or not _valid_bits(second):
        return None
    return first, second


def _weights(count: int) -> list[int]:
    values = [1, 2]
    while len(values) < count:
        values.append(values[-1] + values[-2])
    return values[:count]


def _decode(bits: list[int]) -> int:
    weights = _weights(len(bits))
    return sum(bit * weights[len(bits) - index - 1]
               for index, bit in enumerate(bits))


def _encode(value: int) -> bytes:
    if value == 0:
        return b"0"
    weights = [1, 2]
    while weights[-1] <= value:
        weights.append(weights[-1] + weights[-2])
    weights.pop()  # the last appended term is the first one above value
    remaining = value
    digits: list[int] = []
    for weight in reversed(weights):
        if weight <= remaining:
            digits.append(1)
            remaining -= weight
        else:
            digits.append(0)
    while len(digits) > 1 and digits[0] == 0:
        digits.pop(0)
    return bytes(48 + bit for bit in digits)


def expected_output(
    values: Sequence[int] | None,
    output_capacity: int | None = None,
    output_is_null: bool = False,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> tuple[int, bytes]:
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or output_capacity is not None
            and (type(output_capacity) is not int or output_capacity < 0)
            or input_length is not None
            and (type(input_length) is not int or not 0 <= input_length <= MAX_PARSEABLE_INPUT_LENGTH)
            or input_is_null and values not in (None, [], ())
            or not input_is_null and values is not None and not isinstance(values, (list, tuple))
            or not input_is_null and values is not None and input_length is not None
            and input_length != len(values)):
        return -1, b""
    if input_is_null or values is None or not isinstance(values, (list, tuple)):
        return -1, b""
    if (input_length is not None and input_length != len(values)
            or any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values)):
        return -1, b""
    parsed = _parse(values)
    if parsed is None:
        return -1, b""
    output = _encode(_decode(parsed[0]) + _decode(parsed[1]))
    if output_is_null or output_capacity is not None and output_capacity < len(output):
        return -2, b""
    return len(output), output


expected_call = expected_output
