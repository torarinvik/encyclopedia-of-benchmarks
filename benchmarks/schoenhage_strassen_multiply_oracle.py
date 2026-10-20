"""Independent arbitrary-precision oracle for bounded Schönhage-Strassen multiplication."""
from __future__ import annotations

from collections.abc import Sequence

LIMBS = 513
MAX_INPUT_LENGTH = 1 + 2 * LIMBS
MAX_OUTPUT_LENGTH = 129
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1


def expected_output(
    values: Sequence[int] | None,
    output_capacity: int | None = None,
    output_is_null: bool = False,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> tuple[int, bytes]:
    """Validate fixed-width little-endian bit operands and return product bytes."""
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or input_is_null or not isinstance(values, (list, tuple))
            or len(values) != MAX_INPUT_LENGTH
            or (input_length is not None
                and (type(input_length) is not int or input_length != len(values)))
            or any(type(x) is not int or not I64_MIN <= x <= I64_MAX for x in values)):
        return -1, b""
    if values[0] != LIMBS:
        return -1, b""
    a_limbs = values[1:1 + LIMBS]
    b_limbs = values[1 + LIMBS:]
    if (any(x < 0 or x > 1 for x in a_limbs + b_limbs)
            or a_limbs[-1] != 1 or b_limbs[-1] != 1):
        return -1, b""
    if output_capacity is not None and (
            type(output_capacity) is not int or output_capacity < 0):
        return -1, b""
    a = sum(bit << i for i, bit in enumerate(a_limbs))
    b = sum(bit << i for i, bit in enumerate(b_limbs))
    product = a * b
    result = product.to_bytes(MAX_OUTPUT_LENGTH, "big")
    if len(result) > MAX_OUTPUT_LENGTH:
        return -1, b""
    if output_is_null or (output_capacity is not None and output_capacity < len(result)):
        return -2, b""
    return len(result), result
