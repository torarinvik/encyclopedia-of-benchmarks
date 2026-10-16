"""Independent bounded decimal oracle for the Go Spigot(n) API."""

from __future__ import annotations

from decimal import Decimal, localcontext

MAX_DIGITS = 256
MAX_INPUT_LENGTH = 2
MAX_OUTPUT_BYTES = MAX_DIGITS
INVALID_RESULT = -1
INSUFFICIENT_CAPACITY_RESULT = -2
I64_MIN, I64_MAX = -(1 << 63), (1 << 63) - 1


def _pi_digits(count: int) -> bytes:
    """Compute pi independently with the Chudnovsky series and return count digits."""
    if count == 0:
        return b""
    with localcontext() as context:
        context.prec = count + 24
        multiplier = 1
        linear = 13_591_409
        power = 1
        step = 6
        series = Decimal(linear)
        for index in range(1, count // 14 + 3):
            multiplier = (step * step * step - 16 * step) * multiplier // (index ** 3)
            linear += 545_140_134
            power *= -262_537_412_640_768_000
            series += Decimal(multiplier * linear) / power
            step += 12
        pi = Decimal(426_880) * Decimal(10_005).sqrt() / series
        rendered = format(pi, f".{count - 1}f").replace(".", "")
        return rendered[:count].encode("ascii")


def expected_output(values: list[int] | tuple[int, ...],
                    output_capacity: int | None = None) -> tuple[int, bytes]:
    """Return n leading decimal digits of pi or an ABI status."""
    if (not isinstance(values, (list, tuple)) or len(values) != 1
            or type(values[0]) is not int or not I64_MIN <= values[0] <= I64_MAX):
        return INVALID_RESULT, b""
    count = values[0]
    if not 0 <= count <= MAX_DIGITS:
        return INVALID_RESULT, b""
    if output_capacity is not None:
        if type(output_capacity) is not int or output_capacity < 0:
            return INVALID_RESULT, b""
        if output_capacity < count:
            return INSUFFICIENT_CAPACITY_RESULT, b""
    result = _pi_digits(count)
    return len(result), result
