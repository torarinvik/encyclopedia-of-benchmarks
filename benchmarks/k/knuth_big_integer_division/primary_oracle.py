"""Algorithm D reference for bounded unsigned decimal division."""

from __future__ import annotations

from collections.abc import Sequence

BASE = 1_000_000_000
MAX_DIGITS = 64
MAX_INPUT = 2 + 2 * MAX_DIGITS
MAX_OUTPUT = 2 * MAX_DIGITS + 1


def _bad() -> tuple[int, bytes]:
    return -1, b""


def _limbs(text: bytes) -> list[int]:
    result: list[int] = []
    for byte in text:
        carry = byte - 48
        for index, limb in enumerate(result):
            carry += limb * 10
            result[index] = carry % BASE
            carry //= BASE
        if carry:
            result.append(carry)
    return result


def _format(value: list[int]) -> bytes:
    while value and value[-1] == 0:
        value.pop()
    if not value:
        return b"0"
    pieces = [str(value[-1]).encode("ascii")]
    pieces.extend(f"{limb:09d}".encode("ascii") for limb in reversed(value[:-1]))
    return b"".join(pieces)


def _algorithm_d(dividend: list[int], divisor: list[int]) -> tuple[list[int], list[int]]:
    while dividend and dividend[-1] == 0:
        dividend.pop()
    while divisor and divisor[-1] == 0:
        divisor.pop()
    if not dividend or len(dividend) < len(divisor) or (
        len(dividend) == len(divisor) and dividend[::-1] < divisor[::-1]
    ):
        return [], dividend
    if len(divisor) == 1:
        quotient = [0] * len(dividend)
        remainder = 0
        for index in range(len(dividend) - 1, -1, -1):
            current = remainder * BASE + dividend[index]
            quotient[index], remainder = divmod(current, divisor[0])
        return quotient, [remainder] if remainder else []

    n = len(divisor)
    scale = BASE // (divisor[-1] + 1)
    normalized_divisor = []
    carry = 0
    for limb in divisor:
        current = limb * scale + carry
        normalized_divisor.append(current % BASE)
        carry = current // BASE
    normalized_dividend = []
    carry = 0
    for limb in dividend:
        current = limb * scale + carry
        normalized_dividend.append(current % BASE)
        carry = current // BASE
    normalized_dividend.append(carry)

    quotient_width = len(dividend) - n + 1
    quotient = [0] * quotient_width
    for shift in range(quotient_width - 1, -1, -1):
        numerator = normalized_dividend[shift + n] * BASE + normalized_dividend[shift + n - 1]
        estimate, rem_estimate = divmod(numerator, normalized_divisor[n - 1])
        if estimate >= BASE:
            estimate = BASE - 1
            rem_estimate = numerator - estimate * normalized_divisor[n - 1]
        while (rem_estimate < BASE and
               estimate * normalized_divisor[n - 2] >
               rem_estimate * BASE + normalized_dividend[shift + n - 2]):
            estimate -= 1
            rem_estimate += normalized_divisor[n - 1]

        borrow = 0
        for index in range(n):
            product = estimate * normalized_divisor[index] + borrow
            low = product % BASE
            borrow = product // BASE
            difference = normalized_dividend[shift + index] - low
            if difference < 0:
                difference += BASE
                borrow += 1
            normalized_dividend[shift + index] = difference
        top = normalized_dividend[shift + n] - borrow
        if top < 0:
            estimate -= 1
            carry = 0
            for index in range(n):
                total = normalized_dividend[shift + index] + normalized_divisor[index] + carry
                if total >= BASE:
                    total -= BASE
                    carry = 1
                else:
                    carry = 0
                normalized_dividend[shift + index] = total
            normalized_dividend[shift + n] = top + carry
        else:
            normalized_dividend[shift + n] = top
        quotient[shift] = estimate

    remainder = [0] * n
    carry = 0
    for index in range(n - 1, -1, -1):
        current = carry * BASE + normalized_dividend[index]
        remainder[index], carry = divmod(current, scale)
    while quotient and quotient[-1] == 0:
        quotient.pop()
    while remainder and remainder[-1] == 0:
        remainder.pop()
    return quotient, remainder


def expected_output(
    values: Sequence[int] | None,
    output_capacity: int | None = None,
    output_is_null: bool = False,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> tuple[int, bytes]:
    if type(output_is_null) is not bool or type(input_is_null) is not bool:
        return _bad()
    if input_is_null or not isinstance(values, (list, tuple)):
        return _bad()
    if len(values) < 4 or len(values) > MAX_INPUT:
        return _bad()
    if input_length is not None and (type(input_length) is not int or input_length != len(values)):
        return _bad()
    if any(type(value) is not int or not -(1 << 63) <= value < (1 << 63) for value in values):
        return _bad()
    len_a, len_b = values[0], values[1]
    if not 1 <= len_a <= MAX_DIGITS or not 1 <= len_b <= MAX_DIGITS or len(values) != 2 + len_a + len_b:
        return _bad()
    a = values[2:2 + len_a]
    b = values[2 + len_a:]
    for text in (a, b):
        if any(byte < 48 or byte > 57 for byte in text):
            return _bad()
        if len(text) > 1 and text[0] == 48:
            return _bad()
    if b == [48]:
        return _bad()

    quotient, remainder = _algorithm_d(_limbs(bytes(a)), _limbs(bytes(b)))
    result = _format(quotient) + b":" + _format(remainder)
    if len(result) > MAX_OUTPUT:
        return _bad()
    if output_is_null or (output_capacity is not None and
                          (type(output_capacity) is not int or output_capacity < len(result))):
        return -2, b""
    return len(result), result
