"""Independent mathematical oracle for the bounded real-input FFT convolution."""

from __future__ import annotations

import struct
from collections.abc import Sequence

MAX_SIGNAL_LENGTH = 64
MAX_INPUT_LENGTH = 2 + 2 * MAX_SIGNAL_LENGTH + 1  # one extra slot reaches malformed-length handling
MIN_SAMPLE = -64
MAX_SAMPLE = 64
SAMPLE_SCALE = 16
MAX_OUTPUT_VALUES = 2 * (2 * MAX_SIGNAL_LENGTH - 1)  # interleaved real and imaginary parts
MAX_OUTPUT_BYTES = MAX_OUTPUT_VALUES * 8


def expected_output(values: Sequence[int], capacity: int | None = None) -> tuple[int, bytes]:
    """Return the result code and interleaved complex binary64 output bytes."""
    if len(values) < 4 or len(values) > MAX_INPUT_LENGTH:
        return -1, b""
    if any(type(value) is not int or not -(2**63) <= value < 2**63 for value in values):
        return -1, b""

    raw_a_count, raw_b_count = values[0], values[1]
    if not (1 <= raw_a_count <= MAX_SIGNAL_LENGTH and 1 <= raw_b_count <= MAX_SIGNAL_LENGTH):
        return -1, b""
    a_count, b_count = raw_a_count, raw_b_count
    if len(values) != 2 + a_count + b_count:
        return -1, b""

    samples = values[2:]
    if any(sample < MIN_SAMPLE or sample > MAX_SAMPLE for sample in samples):
        return -1, b""

    a = [sample / SAMPLE_SCALE for sample in samples[:a_count]]
    b = [sample / SAMPLE_SCALE for sample in samples[a_count:]]
    result_count = a_count + b_count - 1
    required_bytes = result_count * 16
    if capacity is not None and capacity < required_bytes:
        return -2, b""

    output = bytearray()
    for index in range(result_count):
        start = max(0, index - b_count + 1)
        end = min(index, a_count - 1)
        real = sum(a[k] * b[index - k] for k in range(start, end + 1))
        # Real-only inputs have an exact zero imaginary result; the FFT ports
        # may emit a small residual that the workload's tolerance covers.
        output.extend(struct.pack("<dd", real, 0.0))
    return required_bytes, bytes(output)
