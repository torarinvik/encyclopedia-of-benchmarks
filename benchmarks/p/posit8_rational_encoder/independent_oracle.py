"""Exhaustive rational reference for posit8 rounding.

This oracle constructs each positive codeword's exact Fraction and scans the
entire finite code space. It does not use the primary oracle's binary search or
2**-24 integer-lattice comparisons.
"""

from __future__ import annotations

from collections.abc import Sequence
from fractions import Fraction

MAX_COUNT = 32
MAX_NUMERATOR = 1 << 31
MAX_DENOMINATOR = 1 << 31
MAX_VALID_INPUT_LENGTH = 1 + 2 * MAX_COUNT
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_OUTPUT_BYTES = MAX_COUNT
WORKSPACE_BYTES = 128
INVALID_RESULT = -1
OUTPUT_ERROR = -2
_I64_MIN = -(1 << 63)
_I64_MAX = (1 << 63) - 1


def _value_of_positive_code(code: int) -> Fraction:
    # Parse a bit string as sign | regime | exponent | fraction, consuming
    # absent low-order fields as zero bits as required by the format.
    stream = [(code >> bit) & 1 for bit in range(6, -1, -1)]
    first = stream[0]
    run = 0
    while run < len(stream) and stream[run] == first:
        run += 1
    regime = run - 1 if first else -run
    offset = run
    if offset < len(stream):
        offset += 1  # regime terminator
    exponent = 0
    for _ in range(2):
        exponent <<= 1
        if offset < len(stream):
            exponent |= stream[offset]
            offset += 1
    fraction_bits = stream[offset:]
    fraction = 0
    for bit in fraction_bits:
        fraction = (fraction << 1) | bit
    fraction_width = len(fraction_bits)
    significand = (1 << fraction_width) + fraction
    power = 4 * regime + exponent - fraction_width
    if power >= 0:
        return Fraction(significand << power, 1)
    return Fraction(significand, 1 << (-power))


def _encode_one(numerator: int, denominator: int) -> int:
    if numerator == 0:
        return 0
    negative = numerator < 0
    target = Fraction(-numerator if negative else numerator, denominator)
    minimum = _value_of_positive_code(1)
    maximum = _value_of_positive_code(127)
    if target <= minimum:
        chosen = 1
    elif target >= maximum:
        chosen = 127
    else:
        best_code = 1
        best_distance = abs(target - minimum)
        for code in range(2, 128):
            candidate = _value_of_positive_code(code)
            distance = abs(target - candidate)
            if (distance < best_distance
                    or distance == best_distance
                    and (best_code & 1) != 0 and (code & 1) == 0):
                best_code = code
                best_distance = distance
        chosen = best_code
    return ((-chosen) & 0xFF) if negative else chosen


def _parse(values: Sequence[int] | None, input_is_null: bool,
           input_length: int | None) -> tuple[tuple[int, int], ...] | None:
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple))
            or not 1 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
            or any(type(value) is not int or not _I64_MIN <= value <= _I64_MAX
                   for value in values)):
        return None
    if input_length is not None and (
            type(input_length) is not int or input_length != len(values)):
        return None
    count = values[0]
    if not 0 <= count <= MAX_COUNT or len(values) != 1 + 2 * count:
        return None
    pairs: list[tuple[int, int]] = []
    for index in range(count):
        numerator, denominator = values[1 + 2 * index:3 + 2 * index]
        if (not -MAX_NUMERATOR <= numerator <= MAX_NUMERATOR
                or not 1 <= denominator <= MAX_DENOMINATOR):
            return None
        pairs.append((numerator, denominator))
    return tuple(pairs)


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or capacity is not None and (type(capacity) is not int or capacity < 0)
            or input_length is not None and (
                type(input_length) is not int
                or not 0 <= input_length <= MAX_PARSEABLE_INPUT_LENGTH)
            or input_is_null and values not in (None, [], ())
            or not input_is_null and values is not None and input_length is not None
            and (not isinstance(values, (list, tuple)) or input_length != len(values))):
        return INVALID_RESULT, b""
    if input_is_null or values is None:
        return INVALID_RESULT, b""
    pairs = _parse(values, input_is_null, input_length)
    if pairs is None:
        return INVALID_RESULT, b""
    staged = bytes(_encode_one(numerator, denominator)
                   for numerator, denominator in pairs)
    if output_is_null or capacity is not None and capacity < len(staged):
        return OUTPUT_ERROR, b""
    return len(staged), staged
