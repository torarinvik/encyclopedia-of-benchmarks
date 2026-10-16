"""Oracle for the bounded kernel-only Gabor filter contract."""
from __future__ import annotations

import math
import struct

MAX_KERNEL_SIZE = 7
MAX_VALID_INPUT_LENGTH = 6
MAX_PARSEABLE_INPUT_LENGTH = 7
MAX_OUTPUT_BYTES = MAX_KERNEL_SIZE * MAX_KERNEL_SIZE * 4
INVALID_RESULT = -1
INSUFFICIENT_CAPACITY_RESULT = -2
_PI = 3.14159265358979323846264338327950288


def expected_output(values: list[int], output_capacity: int | None = None) -> tuple[int, bytes]:
    if (not isinstance(values, (list, tuple))
            or not 1 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return INVALID_RESULT, b""
    if len(values) != MAX_VALID_INPUT_LENGTH:
        return INVALID_RESULT, b""
    ksize, sigma, theta, wavelength, gamma, psi = values
    if not 1 <= ksize <= MAX_KERNEL_SIZE:
        return INVALID_RESULT, b""
    if not 1 <= sigma <= 8 or not 1 <= wavelength <= 8:
        return INVALID_RESULT, b""
    if not 0 <= theta <= 359 or not 0 <= gamma <= 4 or not -6 <= psi <= 6:
        return INVALID_RESULT, b""

    size = ksize + (ksize % 2 == 0)
    theta_radians = theta / 180.0 * _PI
    cosine = math.cos(theta_radians)
    sine = math.sin(theta_radians)
    center = size // 2
    encoded = bytearray()
    for y in range(size):
        py = y - center
        for x in range(size):
            px = x - center
            kernel_x = cosine * px + sine * py
            kernel_y = -sine * px + cosine * py
            numerator = kernel_x**2 + gamma**2 * kernel_y**2
            denominator = 2 * sigma**2
            envelope = math.exp(-numerator / denominator)
            phase = 2 * _PI * kernel_x / wavelength + psi
            value = envelope * math.cos(phase)
            encoded.extend(struct.pack("<f", value))

    output = bytes(encoded)
    if output_capacity is not None and output_capacity < len(output):
        return INSUFFICIENT_CAPACITY_RESULT, b""
    return len(output), output
