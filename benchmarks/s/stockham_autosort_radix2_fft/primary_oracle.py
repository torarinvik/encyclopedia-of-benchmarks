"""Bounded radix-2 Stockham autosort FFT reference."""

from __future__ import annotations

import math
from collections.abc import Sequence

TAU = 2.0 * math.pi
MAX_N = 64
MAX_INPUT_LENGTH = 1 + 2 * MAX_N + 1
MAX_VALID_INPUT_LENGTH = MAX_INPUT_LENGTH - 1
MAX_OUTPUT_ELEMENTS = 2 * MAX_N
ABSOLUTE_TOLERANCE = 1e-9
RELATIVE_TOLERANCE = 1e-12
WORKSPACE_ELEMENTS = 2 * MAX_OUTPUT_ELEMENTS


def _decode(values: Sequence[int | float] | None, input_length: int | None,
            input_is_null: bool) -> tuple[int, list[float]] | None:
    if input_is_null or not isinstance(values, (list, tuple)):
        return None
    if input_length is not None and (
            type(input_length) is not int or input_length != len(values)):
        return None
    if not 3 <= len(values) <= MAX_INPUT_LENGTH:
        return None
    converted: list[float] = []
    for value in values:
        if type(value) not in (int, float):
            return None
        try:
            number = float(value)
        except OverflowError:
            return None
        if not math.isfinite(number):
            return None
        converted.append(number)
    n_value = converted[0]
    if not n_value.is_integer():
        return None
    n = int(n_value)
    if n < 1 or n > MAX_N or n & (n - 1) or len(values) != 1 + 2 * n:
        return None
    samples = converted[1:]
    if any(value < -8.0 or value > 8.0 for value in samples):
        return None
    return n, samples


def stockham(values: Sequence[int | float]) -> list[float]:
    """Return natural-order bins from alternating autosort stages."""
    n = int(float(values[0]))
    source = [float(value) for value in values[1:]]
    destination = [0.0] * (2 * n)
    stride = 1
    while stride < n:
        for j in range(n // 2):
            column = j % stride
            group = j // stride
            base = group * 2 * stride + column
            angle = -TAU * column / (2 * stride)
            cosine = math.cos(angle)
            sine = math.sin(angle)
            left = 2 * j
            right = 2 * (j + n // 2)
            product_real = cosine * source[right] - sine * source[right + 1]
            product_imag = cosine * source[right + 1] + sine * source[right]
            first_real = source[left]
            first_imag = source[left + 1]
            out_left = 2 * base
            out_right = 2 * (base + stride)
            destination[out_left] = first_real + product_real
            destination[out_left + 1] = first_imag + product_imag
            destination[out_right] = first_real - product_real
            destination[out_right + 1] = first_imag - product_imag
        source, destination = destination, source
        stride *= 2
    return source


def expected_output(values: Sequence[int | float] | None,
                    output_capacity: int | None = None,
                    output_is_null: bool = False,
                    input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, list[float]]:
    if type(output_is_null) is not bool or type(input_is_null) is not bool:
        return -1, []
    if output_capacity is not None and (
            type(output_capacity) is not int or output_capacity < 0):
        return -1, []
    if input_length is not None and (
            type(input_length) is not int or not 0 <= input_length <= MAX_INPUT_LENGTH):
        return -1, []
    parsed = _decode(values, input_length, input_is_null)
    if parsed is None:
        return -1, []
    _n, _samples = parsed
    result = stockham(values)
    if output_is_null or (
            output_capacity is not None and output_capacity < len(result)):
        return -2, []
    return len(result), result
