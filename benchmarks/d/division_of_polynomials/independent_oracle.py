"""Reverse-series quotient oracle with a reconstructed remainder."""

from __future__ import annotations

from collections.abc import Sequence
import struct

P = 998_244_353
N_LIMIT = 64
PARSE_LIMIT = 131
OUTPUT_LIMIT = 536


def _bad() -> tuple[int, bytes]:
    return -1, b""


def _encode(quotient: list[int], remainder: list[int]) -> tuple[int, bytes]:
    while quotient and quotient[-1] == 0:
        quotient.pop()
    while remainder and remainder[-1] == 0:
        remainder.pop()
    words = [len(quotient), len(remainder), *quotient, *remainder]
    payload = b"".join(struct.pack("<q", word) for word in words)
    if len(payload) > OUTPUT_LIMIT:
        return -1, b""
    return len(payload), payload


def expected_output(
    words: Sequence[int] | None,
    output_capacity: int | None = None,
    output_is_null: bool = False,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> tuple[int, bytes]:
    if type(output_is_null) is not bool or type(input_is_null) is not bool:
        return _bad()
    if input_is_null or not isinstance(words, (list, tuple)):
        return _bad()
    size = len(words)
    if size < 4 or size > PARSE_LIMIT:
        return _bad()
    if input_length is not None and (type(input_length) is not int or input_length != size):
        return _bad()
    if any(type(word) is not int or not -(1 << 63) <= word < (1 << 63) for word in words):
        return _bad()

    n, m = words[0], words[1]
    if n < 1 or n > N_LIMIT or m < 1 or m > N_LIMIT or size != 2 + n + m:
        return _bad()
    dividend = list(words[2:2 + n])
    divisor = list(words[2 + n:])
    if dividend[-1] == 0 or divisor[-1] == 0:
        return _bad()
    if any(coefficient < 0 or coefficient >= P for coefficient in dividend + divisor):
        return _bad()

    if n >= m:
        quotient_width = n - m + 1
        reversed_divisor = divisor[::-1]
        reciprocal = [0] * quotient_width
        reciprocal[0] = pow(reversed_divisor[0], P - 2, P)
        for degree in range(1, quotient_width):
            convolution = 0
            for index in range(1, min(degree, m - 1) + 1):
                convolution += reversed_divisor[index] * reciprocal[degree - index]
            reciprocal[degree] = -reciprocal[0] * convolution % P

        reversed_dividend = dividend[::-1]
        quotient_reversed = [0] * quotient_width
        for degree in range(quotient_width):
            coefficient = 0
            for index in range(degree + 1):
                coefficient += reversed_dividend[index] * reciprocal[degree - index]
            quotient_reversed[degree] = coefficient % P
        quotient = quotient_reversed[::-1]

        reconstructed = [0] * n
        for i, quotient_coefficient in enumerate(quotient):
            for j, divisor_coefficient in enumerate(divisor):
                reconstructed[i + j] = (
                    reconstructed[i + j] + quotient_coefficient * divisor_coefficient
                ) % P
        residual = [(dividend[i] - reconstructed[i]) % P for i in range(n)]
        remainder = residual[:m]
        if any(residual[m:]):
            return _bad()
    else:
        quotient = []
        remainder = dividend

    payload_length = 8 * (2 + len(quotient) + len(remainder))
    if output_is_null or (output_capacity is not None and
                          (type(output_capacity) is not int or output_capacity < payload_length)):
        return -2, b""
    return _encode(quotient, remainder)
