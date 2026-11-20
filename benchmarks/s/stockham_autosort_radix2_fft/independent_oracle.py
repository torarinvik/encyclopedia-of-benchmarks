"""Direct complex DFT oracle for the Stockham autosort FFT profile."""

from __future__ import annotations

import math
from collections.abc import Sequence

MAX_N = 64
MAX_INPUT_LENGTH = 2 + 2 * MAX_N
MAX_OUTPUT_ELEMENTS = 2 * MAX_N
TAU = 2.0 * math.pi


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
    if input_is_null or not isinstance(values, (list, tuple)):
        return -1, []
    if input_length is not None and input_length != len(values):
        return -1, []
    if not 3 <= len(values) <= MAX_INPUT_LENGTH:
        return -1, []
    numbers: list[float] = []
    for value in values:
        if type(value) not in (int, float):
            return -1, []
        try:
            number = float(value)
        except OverflowError:
            return -1, []
        if not math.isfinite(number):
            return -1, []
        numbers.append(number)
    n_value = numbers[0]
    if not n_value.is_integer():
        return -1, []
    n = int(n_value)
    if n < 1 or n > MAX_N or n & (n - 1) or len(values) != 1 + 2 * n:
        return -1, []
    samples = numbers[1:]
    if any(value < -8.0 or value > 8.0 for value in samples):
        return -1, []

    result: list[float] = []
    for frequency in range(n):
        real_sum = 0.0
        imag_sum = 0.0
        for index in range(n):
            angle = -TAU * index * frequency / n
            cosine = math.cos(angle)
            sine = math.sin(angle)
            real = samples[2 * index]
            imag = samples[2 * index + 1]
            real_sum += real * cosine - imag * sine
            imag_sum += real * sine + imag * cosine
        result.extend((real_sum, imag_sum))
    if output_is_null or (
            output_capacity is not None and output_capacity < len(result)):
        return -2, []
    return len(result), result
