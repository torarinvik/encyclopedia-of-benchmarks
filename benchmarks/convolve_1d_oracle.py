"""Independent oracle for the bounded, center-aligned one-dimensional convolution."""

from __future__ import annotations

import struct

MAX_SIGNAL_LENGTH = 64
MAX_INPUT_LENGTH = 2 + 2 * MAX_SIGNAL_LENGTH
MAX_OUTPUT_VALUES = MAX_SIGNAL_LENGTH
MAX_OUTPUT_BYTES = MAX_OUTPUT_VALUES * 8
SAMPLE_SCALE = 16
MAX_FIXED_SAMPLE = 128
INVALID_RESULT = -1
INSUFFICIENT_CAPACITY_RESULT = -2


def expected_output(input_values: list[int]) -> tuple[int, bytes]:
    """Return (output byte count, little-endian f64 vector), or invalid status."""
    if (not isinstance(input_values, list) or not 2 <= len(input_values) <= MAX_INPUT_LENGTH
            or any(type(value) is not int or not -(2**63) <= value < 2**63 for value in input_values)):
        return INVALID_RESULT, b""

    signal_count, kernel_count = input_values[:2]
    if (not 0 <= signal_count <= MAX_SIGNAL_LENGTH
            or not 0 <= kernel_count <= MAX_SIGNAL_LENGTH
            or len(input_values) != 2 + signal_count + kernel_count):
        return INVALID_RESULT, b""

    signal_fixed = input_values[2:2 + signal_count]
    kernel_fixed = input_values[2 + signal_count:]
    if any(not -MAX_FIXED_SAMPLE <= value <= MAX_FIXED_SAMPLE
           for value in (*signal_fixed, *kernel_fixed)):
        return INVALID_RESULT, b""

    signal = [value / SAMPLE_SCALE for value in signal_fixed]
    kernel = [value / SAMPLE_SCALE for value in kernel_fixed]
    output = [0.0] * signal_count
    center = kernel_count // 2
    for output_index in range(signal_count):
        for kernel_index in range(kernel_count):
            signal_index = output_index + kernel_index - center
            if 0 <= signal_index < signal_count:
                output[output_index] += kernel[kernel_index] * float(signal[signal_index])

    packed = b"".join(struct.pack("<d", value) for value in output)
    return len(packed), packed
