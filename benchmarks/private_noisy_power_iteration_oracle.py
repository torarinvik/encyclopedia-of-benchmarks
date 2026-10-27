"""Fixed-point oracle for a supplied-noise rank-one private power-method trace."""

from __future__ import annotations

import struct
from collections.abc import Sequence

SCALE = 1_000_000
MAX_N = 4
MAX_L = 4
MAX_INPUT = 39
MAX_OUTPUT_BYTES = 32


def _trunc_div(numerator: int, denominator: int) -> int:
    quotient = abs(numerator) // denominator
    return -quotient if numerator < 0 else quotient


def _floor_sqrt(value: int) -> int:
    low, high = 0, 1
    while high <= value // high:
        high *= 2
    while low + 1 < high:
        middle = (low + high) // 2
        if middle <= value // middle:
            low = middle
        else:
            high = middle
    return low


def _parse(values: Sequence[int]) -> tuple[int, int, int, list[int], list[int], list[int]] | None:
    if len(values) < 11 or len(values) > MAX_INPUT or any(
            type(value) is not int or not -(1 << 63) <= value < (1 << 63) for value in values):
        return None
    n, rounds, sigma = values[:3]
    if not 2 <= n <= MAX_N or not 1 <= rounds <= MAX_L or not 0 <= sigma <= SCALE:
        return None
    expected_length = 3 + n*n + n + rounds*n
    if len(values) != expected_length:
        return None
    matrix = list(values[3:3+n*n])
    vector_start = 3 + n*n
    initial = list(values[vector_start:vector_start+n])
    noise = list(values[vector_start+n:])
    if any(abs(value) > SCALE for value in matrix):
        return None
    if any(matrix[i*n+j] != matrix[j*n+i] for i in range(n) for j in range(n)):
        return None
    if any(abs(value) > SCALE for value in initial) or sum(value*value for value in initial) != SCALE*SCALE:
        return None
    if any(abs(value) > 2*SCALE for value in noise):
        return None
    return n, rounds, sigma, matrix, initial, noise


def _iterate(parsed: tuple[int, int, int, list[int], list[int], list[int]]) -> list[int] | None:
    n, rounds, sigma, matrix, vector, noise = parsed
    x = vector[:]
    for step in range(rounds):
        y = [
            _trunc_div(sum(matrix[i*n+j] * x[j] for j in range(n)) + sigma * noise[step*n+i], SCALE)
            for i in range(n)
        ]
        squared_norm = sum(value*value for value in y)
        if squared_norm == 0:
            return None
        radius = _floor_sqrt(squared_norm)
        x = [_trunc_div(value*SCALE, radius) for value in y]
    return x


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or capacity is not None and (type(capacity) is not int or capacity < 0)
            or input_length is not None and (type(input_length) is not int or not 0 <= input_length <= MAX_INPUT)
            or input_is_null and values not in (None, [], ())
            or not input_is_null and values is not None and input_length is not None and input_length != len(values)):
        return -1, b""
    if input_is_null or values is None or not isinstance(values, (list, tuple)):
        return -1, b""
    parsed = _parse(values)
    if parsed is None:
        return -1, b""
    result = _iterate(parsed)
    if result is None:
        return -1, b""
    payload = b"".join(struct.pack("<q", value) for value in result)
    if output_is_null or capacity is not None and capacity < len(payload):
        return -2, b""
    return len(payload), payload
