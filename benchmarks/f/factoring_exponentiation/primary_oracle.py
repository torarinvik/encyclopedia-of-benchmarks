"""Factoring-based exponentiation in the 2-adic unit group, bounded to 32 bits."""

from __future__ import annotations

from collections.abc import Sequence

ALGORITHM = "factoring_exponentiation"
MAX_VALID_INPUT_LENGTH = 4
MAX_PARSEABLE_INPUT_LENGTH = 5
MAX_EXPONENT = (1 << 32) - 1
INVALID_RESULT = -1
WORKSPACE_BYTES = 512

_LOG_TABLE = (
    0x00000000, 0x00000000, 0xd3cfd984, 0x9ee62e18,
    0xe83d9070, 0xb59e81e0, 0xa17407c0, 0xce601f80,
    0xf4807f00, 0xe701fe00, 0xbe07fc00, 0xfc1ff800,
    0xf87ff000, 0xf1ffe000, 0xe7ffc000, 0xdfff8000,
    0xffff0000, 0xfffe0000, 0xfffc0000, 0xfff80000,
    0xfff00000, 0xffe00000, 0xffc00000, 0xff800000,
    0xff000000, 0xfe000000, 0xfc000000, 0xf8000000,
    0xf0000000, 0xe0000000, 0xc0000000, 0x80000000,
)


def _parse(
    values: Sequence[int] | None,
    input_is_null: bool,
    input_length: int | None,
) -> tuple[int, int, int, int] | None:
    if (
        type(input_is_null) is not bool
        or input_is_null
        or not isinstance(values, (list, tuple))
        or (input_length is not None and (type(input_length) is not int or input_length != len(values)))
        or not 0 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
        or len(values) != MAX_VALID_INPUT_LENGTH
        or any(type(value) is not int or not -(1 << 63) <= value <= (1 << 63) - 1 for value in values)
    ):
        return None
    remainder, base, exponent, d = values
    if not 3 <= d <= 32 or remainder < 0 or base < 1 or not 0 <= exponent <= MAX_EXPONENT:
        return None
    modulus = 1 << d
    if remainder >= modulus or base >= modulus or base % 2 == 0:
        return None
    return remainder, base, exponent, d


def _mask(d: int) -> int:
    return (1 << d) - 1


def _factoring_log(remainder: int, value: int, d: int, modulus: int, mask: int) -> int:
    for bit in range(2, d):
        if value & (1 << bit):
            value = (value + (value << bit)) & mask
            remainder = (remainder + modulus - (_LOG_TABLE[bit] & mask)) & mask
    return remainder


def _factoring_exp(remainder: int, exponent: int, d: int, modulus: int, mask: int) -> int:
    for bit in range(2, d):
        if exponent & (1 << bit):
            remainder = (remainder + (remainder << bit)) & mask
            exponent = (exponent + modulus - (_LOG_TABLE[bit] & mask)) & mask
    return remainder


def expected_result(
    values: Sequence[int] | None,
    *,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> int:
    """Apply the bit-factored 2-adic logarithm/exponential steps."""
    parsed = _parse(values, input_is_null, input_length)
    if parsed is None:
        return INVALID_RESULT
    remainder, base, exponent, d = parsed
    mask = _mask(d)
    modulus = mask + 1
    if base & 2:
        base = (modulus - base) & mask
        if exponent & 1:
            remainder = (modulus - remainder) & mask
    log_value = _factoring_log(0, base, d, modulus, mask)
    return _factoring_exp(remainder, (log_value * exponent) & mask, d, modulus, mask)
