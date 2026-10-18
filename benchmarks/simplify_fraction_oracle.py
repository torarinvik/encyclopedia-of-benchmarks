"""Oracle for the bounded primelib simplify_fraction tuple routine."""

from __future__ import annotations

from collections.abc import Sequence
import math
import struct

MAX_ABS_COMPONENT = 1_000_000
MAX_INPUT_LENGTH = 3
OUTPUT_BYTES = 16
INVALID_RESULT = -1
OUTPUT_ERROR = -2


def expected_result(values: Sequence[int] | None) -> tuple[int, int] | None:
    """Return the reduced numerator/denominator pair, or None for invalid input."""
    if not isinstance(values, (list, tuple)) or len(values) != 2:
        return None
    if any(type(value) is not int or not -(1 << 63) <= value < (1 << 63) for value in values):
        return None
    numerator, denominator = values
    if (
        abs(numerator) > MAX_ABS_COMPONENT
        or abs(denominator) > MAX_ABS_COMPONENT
        or denominator == 0
    ):
        return None
    divisor = math.gcd(abs(numerator), abs(denominator))
    return numerator // divisor, denominator // divisor


def expected_output(
    values: Sequence[int] | None,
    output_capacity: int | None = None,
    output_is_null: bool = False,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> tuple[int, bytes]:
    """Return status and the little-endian signed pair for the byte-output ABI."""
    if type(output_is_null) is not bool or type(input_is_null) is not bool:
        return INVALID_RESULT, b""
    if output_capacity is not None and (
        type(output_capacity) is not int or output_capacity < 0
    ):
        return INVALID_RESULT, b""
    if input_length is not None and (
        type(input_length) is not int or input_length < 0
    ):
        return INVALID_RESULT, b""
    if input_is_null or not isinstance(values, (list, tuple)):
        return INVALID_RESULT, b""
    if input_length is not None and input_length != len(values):
        return INVALID_RESULT, b""

    pair = expected_result(values)
    if pair is None:
        return INVALID_RESULT, b""
    if output_is_null or (output_capacity is not None and output_capacity < OUTPUT_BYTES):
        return OUTPUT_ERROR, b""
    return OUTPUT_BYTES, struct.pack("<qq", *pair)
