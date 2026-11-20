"""Direct digit-reversal reference for bounded Van der Corput terms."""

from __future__ import annotations

from collections.abc import Sequence

MAX_INDEX = 4096
MAX_COUNT = 128
MAX_PARSEABLE_INPUT_LENGTH = 4
INVALID_RESULT = -1
OUTPUT_ERROR = -2


def _parse(values: Sequence[int] | None, input_is_null: bool,
           input_length: int | None) -> tuple[int, int, int] | None:
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple))
            or not 1 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
            or any(type(word) is not int or not -(1 << 63) <= word < (1 << 63)
                   for word in values)):
        return None
    actual_length = len(values) if input_length is None else input_length
    if type(actual_length) is not int or actual_length != len(values) or len(values) != 3:
        return None
    base, first_index, count = values
    if not 2 <= base <= 16 or not 1 <= first_index <= MAX_INDEX or not 0 <= count <= MAX_COUNT:
        return None
    if count > 0 and first_index + count - 1 > MAX_INDEX:
        return None
    return base, first_index, count


def _digit_reversal(index: int, base: int) -> tuple[int, int]:
    numerator = 0
    denominator = 1
    remaining = index
    while remaining > 0:
        numerator = numerator * base + remaining % base
        denominator *= base
        remaining //= base
    return numerator, denominator


def _encode(pairs: Sequence[tuple[int, int]]) -> bytes:
    return b"".join(
        numerator.to_bytes(8, "little", signed=True)
        + denominator.to_bytes(8, "little", signed=True)
        for numerator, denominator in pairs
    )


def expected_output(values: Sequence[int] | None, input_is_null: bool = False,
                    input_length: int | None = None, output_is_null: bool = False,
                    output_capacity: int | None = None) -> tuple[int, bytes]:
    parsed = _parse(values, input_is_null, input_length)
    if parsed is None:
        return INVALID_RESULT, b""
    base, first_index, count = parsed
    pairs = [_digit_reversal(index, base)
             for index in range(first_index, first_index + count)]
    encoded = _encode(pairs)
    if (type(output_is_null) is not bool or output_is_null
            or (output_capacity is not None
                and (type(output_capacity) is not int or output_capacity < len(encoded)))):
        return OUTPUT_ERROR, b""
    return len(encoded), encoded
