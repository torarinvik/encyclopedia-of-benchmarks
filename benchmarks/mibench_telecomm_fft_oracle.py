"""Independent source-order model for the bounded MiBench FFT float kernel."""
from __future__ import annotations

import math
import struct

MAX_N = 16
MAX_INPUT_LENGTH = 2 + 2 * MAX_N
MAX_OUTPUT_ELEMENTS = 2 * MAX_N


def _f32(value: float) -> float:
    return struct.unpack("<f", struct.pack("<f", value))[0]


def expected_output(values: list[float]) -> list[float] | None:
    if (not isinstance(values, (list, tuple)) or len(values) < 2
            or len(values) > MAX_INPUT_LENGTH
            or any(type(value) not in (int, float) or not math.isfinite(float(value))
                   for value in values)):
        return None
    n_value, inverse_value = float(values[0]), float(values[1])
    if (n_value != math.trunc(n_value) or inverse_value != math.trunc(inverse_value)
            or not 2 <= n_value <= MAX_N or inverse_value not in (0.0, 1.0)):
        return None
    n, inverse = int(n_value), int(inverse_value)
    if n & (n - 1) or len(values) != 2 + 2 * n:
        return None
    samples = [float(value) for value in values[2:]]
    if any(abs(value) > 8.0 for value in samples):
        return None
    real_in = [_f32(value) for value in samples[:n]]
    imag_in = [_f32(value) for value in samples[n:]]
    real_out = [0.0] * n
    imag_out = [0.0] * n
    bits = n.bit_length() - 1
    for index in range(n):
        reverse = 0
        source_index = index
        for _ in range(bits):
            reverse = (reverse << 1) | (source_index & 1)
            source_index >>= 1
        real_out[reverse] = real_in[index]
        imag_out[reverse] = imag_in[index]

    angle_numerator = -2.0 * math.pi if inverse else 2.0 * math.pi
    block_end = 1
    block_size = 2
    while block_size <= n:
        delta = angle_numerator / float(block_size)
        sm2, sm1 = math.sin(-2.0 * delta), math.sin(-delta)
        cm2, cm1 = math.cos(-2.0 * delta), math.cos(-delta)
        w = 2.0 * cm1
        start = 0
        while start < n:
            ar2, ar1 = cm2, cm1
            ai2, ai1 = sm2, sm1
            for offset in range(block_end):
                ar0 = w * ar1 - ar2
                ar2, ar1 = ar1, ar0
                ai0 = w * ai1 - ai2
                ai2, ai1 = ai1, ai0
                first, second = start + offset, start + offset + block_end
                tr = ar0 * real_out[second] - ai0 * imag_out[second]
                ti = ar0 * imag_out[second] + ai0 * real_out[second]
                real_out[second] = _f32(real_out[first] - tr)
                imag_out[second] = _f32(imag_out[first] - ti)
                real_out[first] = _f32(real_out[first] + tr)
                imag_out[first] = _f32(imag_out[first] + ti)
            start += block_size
        block_end = block_size
        block_size *= 2
    if inverse:
        for index in range(n):
            real_out[index] = _f32(real_out[index] / float(n))
            imag_out[index] = _f32(imag_out[index] / float(n))
    return [component for pair in zip(real_out, imag_out) for component in pair]
