"""Independent fixed-width unsigned division/remainder oracle for uint128_t/uint256_t."""

from __future__ import annotations

from collections.abc import Sequence

U32_MAX = (1 << 32) - 1
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1
INVALID_RESULT = -1
OUTPUT_ERROR = -2


def expected_output(
    bits: int,
    values: Sequence[int] | None,
    output_capacity: int | None = None,
    output_is_null: bool = False,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> tuple[int, bytes]:
    """Return fixed-width little-endian limbs of the quotient or remainder."""
    if bits not in (128, 256):
        return INVALID_RESULT, b""
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
    if input_is_null or values is None or not isinstance(values, (list, tuple)):
        return INVALID_RESULT, b""
    if input_length is not None and input_length != len(values):
        return INVALID_RESULT, b""
    limb_count = bits // 32
    valid_length = 1 + 2 * limb_count
    if not valid_length <= len(values) <= valid_length + 1:
        return INVALID_RESULT, b""
    if any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values):
        return INVALID_RESULT, b""

    operation = values[0]
    limbs = values[1:]
    if operation not in (0, 1) or len(limbs) != 2 * limb_count:
        return INVALID_RESULT, b""
    if any(not 0 <= limb <= U32_MAX for limb in limbs):
        return INVALID_RESULT, b""
    dividend_limbs = limbs[:limb_count]
    divisor_limbs = limbs[limb_count:]
    dividend = sum(limb << (32 * index) for index, limb in enumerate(dividend_limbs))
    divisor = sum(limb << (32 * index) for index, limb in enumerate(divisor_limbs))
    if divisor == 0:
        return INVALID_RESULT, b""
    result = dividend // divisor if operation == 0 else dividend % divisor
    output = result.to_bytes(bits // 8, "little", signed=False)
    if output_is_null or (output_capacity is not None and output_capacity < len(output)):
        return OUTPUT_ERROR, b""
    return len(output), output
