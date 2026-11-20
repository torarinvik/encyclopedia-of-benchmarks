"""Radix-2 spectral Hamiltonian expectation reference."""

from __future__ import annotations

import math
from typing import Sequence

NORM_SCALE = 256
MAX_N = 32
MAX_VALID_INPUT_LENGTH = 1 + 3 * MAX_N
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
INVALID_RESULT = -1.0e300
TAU = 6.283185307179586476925286766559005768


def _parse(values: Sequence[int] | None, input_is_null: bool,
           input_length: int | None):
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple))
            or not 1 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)
            or input_length is not None and (
                type(input_length) is not int or input_length != len(values))):
        return None
    n = values[0]
    if n < 2 or n > MAX_N or n & (n - 1) or len(values) != 1 + 3 * n:
        return None
    potential = values[1:1 + n]
    real = values[1 + n:1 + 2 * n]
    imag = values[1 + 2 * n:]
    if any(abs(value) > 2048 for value in potential):
        return None
    if any(abs(value) > 2048 for value in (*real, *imag)):
        return None
    if sum(re * re + im * im for re, im in zip(real, imag)) != NORM_SCALE**2 * n:
        return None
    return n, potential, real, imag


def _fft(real: list[float], imag: list[float], inverse: bool = False) -> None:
    n = len(real)
    j = 0
    for i in range(1, n):
        bit = n >> 1
        while j & bit:
            j ^= bit
            bit >>= 1
        j ^= bit
        if i < j:
            real[i], real[j] = real[j], real[i]
            imag[i], imag[j] = imag[j], imag[i]
    width = 2
    direction = 1.0 if inverse else -1.0
    while width <= n:
        angle = direction * TAU / width
        step_re, step_im = math.cos(angle), math.sin(angle)
        half = width >> 1
        for start in range(0, n, width):
            twiddle_re, twiddle_im = 1.0, 0.0
            for offset in range(half):
                even = start + offset
                odd = even + half
                odd_re = real[odd] * twiddle_re - imag[odd] * twiddle_im
                odd_im = real[odd] * twiddle_im + imag[odd] * twiddle_re
                real[odd] = real[even] - odd_re
                imag[odd] = imag[even] - odd_im
                real[even] += odd_re
                imag[even] += odd_im
                twiddle_re, twiddle_im = (
                    twiddle_re * step_re - twiddle_im * step_im,
                    twiddle_re * step_im + twiddle_im * step_re,
                )
        width <<= 1
    if inverse:
        for i in range(n):
            real[i] /= n
            imag[i] /= n


def expected_result(values: Sequence[int] | None, *, input_is_null: bool = False,
                    input_length: int | None = None) -> float:
    parsed = _parse(values, input_is_null, input_length)
    if parsed is None:
        return INVALID_RESULT
    n, potential, fixed_real, fixed_imag = parsed
    real = [value / NORM_SCALE for value in fixed_real]
    imag = [value / NORM_SCALE for value in fixed_imag]
    _fft(real, imag)
    for index in range(n):
        frequency = index if index <= n // 2 else index - n
        wave_number = TAU * frequency
        multiplier = 0.5 * wave_number * wave_number
        real[index] *= multiplier
        imag[index] *= multiplier
    _fft(real, imag, inverse=True)

    total = 0.0
    for index in range(n):
        psi_real = fixed_real[index] / NORM_SCALE
        psi_imag = fixed_imag[index] / NORM_SCALE
        local_potential = potential[index] / NORM_SCALE
        h_real = real[index] + local_potential * psi_real
        h_imag = imag[index] + local_potential * psi_imag
        total += psi_real * h_real + psi_imag * h_imag
    return total / n
