"""Bounded deterministic NBench back-propagation kernel profile."""
from __future__ import annotations

import math
import struct
from typing import Sequence

MAX_PARSEABLE_INPUT_LENGTH = 2
MAX_VALID_INPUT_LENGTH = 1
MAX_OUTPUT_BYTES = 88
INVALID_RESULT = -1
OUTPUT_ERROR = -2
SCALE = 1_000_000

_PATTERN = [
    0, 1, 1, 1, 0,
    1, 0, 0, 0, 1,
    1, 0, 0, 0, 1,
    1, 0, 0, 0, 1,
    1, 0, 0, 0, 1,
    1, 0, 0, 0, 0,
    0, 1, 1, 1, 0,
]
_TARGET = [0, 1, 0, 0, 1, 1, 1, 1]


def _run(passes: int) -> list[int]:
    mid_wts = [[(((neuron * 17 + weight * 7) % 101) - 50) / 1000.0
                for weight in range(35)] for neuron in range(8)]
    out_wts = [[(((neuron * 13 + weight * 5) % 71) - 35) / 1000.0
                for weight in range(8)] for neuron in range(8)]
    mid_change = [[0.0] * 35 for _ in range(8)]
    out_change = [[0.0] * 8 for _ in range(8)]
    mid_cum = [[0.0] * 35 for _ in range(8)]
    out_cum = [[0.0] * 8 for _ in range(8)]
    mid_out = [0.0] * 8
    out_out = [0.0] * 8

    for _ in range(passes):
        for i in range(8):
            for j in range(35):
                mid_change[i][j] = mid_cum[i][j]
                mid_cum[i][j] = 0.0
        for i in range(8):
            for j in range(8):
                out_change[i][j] = out_cum[i][j]
                out_cum[i][j] = 0.0

        # NBench's do_forward_pass invokes do_mid_forward twice.
        for _forward in range(2):
            for neuron in range(8):
                total = 0.0
                for weight in range(35):
                    total += mid_wts[neuron][weight] * _PATTERN[weight]
                mid_out[neuron] = 1.0 / (1.0 + math.exp(-total))
        for neuron in range(8):
            total = 0.0
            for weight in range(8):
                total += out_wts[neuron][weight] * mid_out[weight]
            out_out[neuron] = 1.0 / (1.0 + math.exp(-total))

        out_error = [_TARGET[i] - out_out[i] for i in range(8)]
        mid_error = [0.0] * 8
        for neuron in range(8):
            total = 0.0
            for i in range(8):
                total += out_wts[i][neuron] * out_error[i]
            mid_error[neuron] = mid_out[neuron] * (1.0 - mid_out[neuron]) * total

        for neuron in range(8):
            for weight in range(8):
                delta = 0.09 * out_error[neuron] * mid_out[weight]
                delta += 0.09 * out_change[neuron][weight]
                out_wts[neuron][weight] += delta
                out_cum[neuron][weight] += delta
        for neuron in range(8):
            for weight in range(35):
                delta = 0.09 * mid_error[neuron] * _PATTERN[weight]
                delta += 0.09 * mid_change[neuron][weight]
                mid_wts[neuron][weight] += delta
                mid_cum[neuron][weight] += delta

    quantize = lambda value: int(value * SCALE)
    mid_sum = 0.0
    for neuron in range(8):
        for weight in range(35):
            mid_sum += mid_wts[neuron][weight]
    out_sum = 0.0
    for neuron in range(8):
        for weight in range(8):
            out_sum += out_wts[neuron][weight]
    return [passes, *(quantize(value) for value in out_out),
            quantize(mid_sum), quantize(out_sum)]


def expected_output(
    values: Sequence[int] | None,
    output_capacity: int | None = None,
    output_is_null: bool = False,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> tuple[int, bytes]:
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or (output_capacity is not None and
                (type(output_capacity) is not int or output_capacity < 0))
            or (input_length is not None and
                (type(input_length) is not int or input_length < 0))):
        return INVALID_RESULT, b""
    if input_is_null or values is None or not isinstance(values, (list, tuple)):
        return INVALID_RESULT, b""
    actual_length = len(values) if input_length is None else input_length
    if (actual_length != 1 or len(values) != 1
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return INVALID_RESULT, b""
    passes = values[0]
    if not 1 <= passes <= 8:
        return INVALID_RESULT, b""
    result = struct.pack("<11q", *_run(passes))
    if output_is_null or (output_capacity is not None and output_capacity < len(result)):
        return OUTPUT_ERROR, b""
    return len(result), result
