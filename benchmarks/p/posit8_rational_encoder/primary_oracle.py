"""Exact posit8 encoder using ordered-code binary search.

The posit8 format uses the two exponent bits specified by the 2022 Posit
Standard. Inputs are bounded rationals, so all rounding comparisons are exact
integer comparisons on the common 2**-24 lattice.
"""

from __future__ import annotations

from collections.abc import Sequence

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


def _code_unit(code: int) -> int:
    """Return a positive posit8 value measured in minPos units."""
    cursor = 6
    regime_bit = (code >> cursor) & 1
    run = 0
    while cursor >= 0 and ((code >> cursor) & 1) == regime_bit:
        run += 1
        cursor -= 1
    regime = run - 1 if regime_bit else -run
    if cursor >= 0:  # consume the regime terminator
        cursor -= 1

    exponent = 0
    for _ in range(2):
        exponent <<= 1
        if cursor >= 0:
            exponent |= (code >> cursor) & 1
            cursor -= 1

    fraction_width = cursor + 1
    fraction = code & ((1 << fraction_width) - 1) if fraction_width else 0
    significand = (1 << fraction_width) + fraction
    unit_shift = 4 * regime + exponent + 24 - fraction_width
    return significand << unit_shift


def _compare_ratio_to_unit(scaled_numerator: int, denominator: int, unit: int) -> int:
    """Compare scaled_numerator/denominator with an integer lattice unit."""
    quotient, remainder = divmod(scaled_numerator, denominator)
    if quotient < unit:
        return -1
    if quotient > unit:
        return 1
    return 0 if remainder == 0 else 1


def _encode_one(numerator: int, denominator: int) -> int:
    if numerator == 0:
        return 0
    negative = numerator < 0
    magnitude = -numerator if negative else numerator
    scaled = magnitude << 24

    # Posit rounding clamps magnitudes beyond either end of the finite range.
    if _compare_ratio_to_unit(scaled, denominator, 1) <= 0:
        positive_code = 1
    elif _compare_ratio_to_unit(scaled, denominator, _code_unit(127)) >= 0:
        positive_code = 127
    else:
        low, high = 1, 127
        while low < high:
            middle = (low + high) // 2
            if _compare_ratio_to_unit(scaled, denominator, _code_unit(middle)) > 0:
                low = middle + 1
            else:
                high = middle
        upper = low
        lower = upper - 1
        midpoint_comparison = _compare_ratio_to_unit(
            scaled << 1, denominator, _code_unit(lower) + _code_unit(upper))
        if midpoint_comparison < 0:
            positive_code = lower
        elif midpoint_comparison > 0:
            positive_code = upper
        else:
            positive_code = lower if (lower & 1) == 0 else upper

    return ((-positive_code) & 0xFF) if negative else positive_code


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
