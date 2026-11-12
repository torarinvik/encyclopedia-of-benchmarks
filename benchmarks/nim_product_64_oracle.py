"""Independent arbitrary-precision oracle for 64-bit nim products."""
from __future__ import annotations

from collections.abc import Sequence

MAX_LIMB = (1 << 32) - 1
MAX_INPUT_LENGTH = 4
MAX_PARSEABLE_INPUT_LENGTH = 5
OUTPUT_BYTES = 8


def _nim_product_direct(a: int, b: int, width: int = 64) -> int:
    """Use the direct four-product extension formula over F_(2^width)."""
    if width == 1:
        return a & b
    half = width // 2
    mask = (1 << half) - 1
    a_low, a_high = a & mask, a >> half
    b_low, b_high = b & mask, b >> half
    low_product = _nim_product_direct(a_low, b_low, half)
    high_product = _nim_product_direct(a_high, b_high, half)
    cross_low = _nim_product_direct(a_low, b_high, half)
    cross_high = _nim_product_direct(a_high, b_low, half)
    square_constant_product = _nim_product_direct(
        high_product, 1 << (half - 1), half)
    low = low_product ^ square_constant_product
    high = cross_low ^ cross_high ^ high_product
    return low ^ (high << half)


def expected_output(values: Sequence[int] | None, output_capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or input_is_null and values not in (None, [], ())):
        return -1, b""
    if input_is_null or not isinstance(values, Sequence):
        return -1, b""
    if input_length is None:
        input_length = len(values)
    if (type(input_length) is not int or input_length < 0
            or input_length > MAX_PARSEABLE_INPUT_LENGTH
            or input_length != len(values) or input_length != MAX_INPUT_LENGTH):
        return -1, b""
    if (any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
            for value in values)
            or any(not 0 <= value <= MAX_LIMB for value in values)):
        return -1, b""
    if output_capacity is None:
        output_capacity = OUTPUT_BYTES
    if type(output_capacity) is not int or output_capacity < 0:
        return -2, b""
    if output_is_null or output_capacity < OUTPUT_BYTES:
        return -2, b""

    a = values[0] | (values[1] << 32)
    b = values[2] | (values[3] << 32)
    result = _nim_product_direct(a, b)
    return OUTPUT_BYTES, result.to_bytes(OUTPUT_BYTES, "little")
