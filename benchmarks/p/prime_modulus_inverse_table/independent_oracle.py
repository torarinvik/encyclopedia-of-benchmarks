"""Per-value extended-Euclid oracle for the prime inverse table profile."""

from __future__ import annotations

import struct
from collections.abc import Sequence

MODULUS = 1_000_000_007
MAX_QUERIES = 32
MAX_VALUE = 256
MAX_VALID_INPUT_LENGTH = MAX_QUERIES + 1
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_OUTPUT_BYTES = MAX_QUERIES * 4
INVALID_RESULT = -1
CAPACITY_ERROR = -2


def _parse(values: Sequence[int] | None, input_is_null: bool,
           input_length: int | None) -> tuple[int, tuple[int, ...]] | None:
    if type(input_is_null) is not bool or input_is_null or not isinstance(values, (list, tuple)):
        return None
    if input_length is None:
        input_length = len(values)
    if (type(input_length) is not int or not 1 <= input_length <= MAX_PARSEABLE_INPUT_LENGTH
            or input_length != len(values)
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63) for value in values)):
        return None
    count = values[0]
    if not 0 <= count <= MAX_QUERIES or len(values) != count + 1:
        return None
    operands = tuple(values[1:])
    if any(not 1 <= value <= MAX_VALUE for value in operands):
        return None
    return count, operands


def _inverse(value: int) -> int:
    old_remainder, remainder = value, MODULUS
    old_coefficient, coefficient = 1, 0
    while remainder:
        quotient = old_remainder // remainder
        old_remainder, remainder = remainder, old_remainder - quotient * remainder
        old_coefficient, coefficient = coefficient, old_coefficient - quotient * coefficient
    return old_coefficient % MODULUS


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    parsed = _parse(values, input_is_null, input_length)
    if parsed is None:
        return INVALID_RESULT, b""
    count, operands = parsed
    if count == 0:
        return 0, b""
    if type(output_is_null) is not bool:
        return CAPACITY_ERROR, b""
    effective_capacity = MAX_OUTPUT_BYTES if capacity is None else capacity
    required = 4 * count
    if (type(effective_capacity) is not int or effective_capacity < 0
            or output_is_null or effective_capacity < required):
        return CAPACITY_ERROR, b""
    payload = b"".join(struct.pack("<I", _inverse(value)) for value in operands)
    return len(payload), payload


def expected_result(values: Sequence[int] | None, **kwargs) -> int:
    return expected_output(values, **kwargs)[0]
