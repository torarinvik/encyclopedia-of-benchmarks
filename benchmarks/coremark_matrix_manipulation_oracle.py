"""Oracle for a bounded fixed-profile CoreMark matrix kernel variant."""
from __future__ import annotations

import struct
from typing import Sequence

MAX_PARSEABLE_INPUT_LENGTH = 20
MAX_VALID_INPUT_LENGTH = 19
MAX_OUTPUT_BYTES = 112
INVALID_RESULT = -1
OUTPUT_ERROR = -2
N = 3


def _crc_byte(value: int, crc: int) -> int:
    value &= 0xFF
    for _ in range(8):
        mix = (value & 1) ^ (crc & 1)
        value >>= 1
        if mix:
            crc ^= 0x4002
        crc >>= 1
        if mix:
            crc |= 0x8000
        else:
            crc &= 0x7FFF
    return crc


def _crc16(value: int, crc: int) -> int:
    value &= 0xFFFF
    crc = _crc_byte(value, crc)
    return _crc_byte(value >> 8, crc)


def _matrix_sum(matrix: list[int], clipval: int) -> int:
    tmp = prev = ret = 0
    for cur in matrix:
        tmp += cur
        if tmp > clipval:
            ret += 10
            tmp = 0
        elif cur > prev:
            ret += 1
        prev = cur
    return ret


def _run(values: Sequence[int]) -> list[int]:
    val = values[0]
    a = list(values[1:10])
    b = list(values[10:19])
    original_a = a.copy()
    for i in range(9):
        a[i] += val
    clipval = 0xF000 | val

    c = [x * val for x in a]
    sums = [_matrix_sum(c, clipval)]

    c = [0] * 9
    for i in range(N):
        total = 0
        for j in range(N):
            total += a[i * N + j] * b[j]
        c[i] = total
    sums.append(_matrix_sum(c, clipval))

    c = [0] * 9
    for i in range(N):
        for j in range(N):
            total = 0
            for k in range(N):
                total += a[i * N + k] * b[k * N + j]
            c[i * N + j] = total
    sums.append(_matrix_sum(c, clipval))

    c = [0] * 9
    for i in range(N):
        for j in range(N):
            total = 0
            for k in range(N):
                product = a[i * N + k] * b[k * N + j]
                total += ((product >> 2) & 0xF) * ((product >> 5) & 0x3)
            c[i * N + j] = total
    sums.append(_matrix_sum(c, clipval))

    crc = 0
    for value in sums:
        crc = _crc16(value, crc)
    for i in range(9):
        a[i] -= val
    return [crc, *sums, *a]


def expected_output(
    values: Sequence[int] | None,
    output_capacity: int | None = None,
    output_is_null: bool = False,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> tuple[int, bytes]:
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or (output_capacity is not None and (type(output_capacity) is not int or output_capacity < 0))
            or (input_length is not None and (type(input_length) is not int or input_length < 0))):
        return INVALID_RESULT, b""
    if input_is_null or values is None or not isinstance(values, (tuple, list)):
        return INVALID_RESULT, b""
    actual_length = len(values) if input_length is None else input_length
    if (actual_length != MAX_VALID_INPUT_LENGTH or len(values) != MAX_VALID_INPUT_LENGTH
            or any(type(v) is not int or not -(1 << 63) <= v < (1 << 63) for v in values)):
        return INVALID_RESULT, b""
    val = values[0]
    if not 0 <= val <= 15 or any(not 0 <= v <= 127 for v in values[1:]):
        return INVALID_RESULT, b""
    result = struct.pack("<14q", *_run(values))
    if output_is_null or (output_capacity is not None and output_capacity < len(result)):
        return OUTPUT_ERROR, b""
    return len(result), result
