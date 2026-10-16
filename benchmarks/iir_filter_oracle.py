"""Oracle for the bounded, fixed-point IIR filter stream contract."""

from __future__ import annotations

import struct

INVALID_RESULT = -1
CAPACITY_ERROR_RESULT = -2
MAX_ORDER = 3
MAX_SAMPLE_COUNT = 16
MAX_INPUT_LENGTH = 26
MAX_PARSEABLE_INPUT_LENGTH = MAX_INPUT_LENGTH + 1
MAX_OUTPUT_BYTES = MAX_SAMPLE_COUNT * 8
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1


def expected_output(
    values: tuple[int, ...] | list[int], output_capacity: int | None = None
) -> tuple[int, bytes]:
    """Return the source recurrence output as little-endian float64 samples."""
    if (
        not isinstance(values, (tuple, list))
        or not 7 <= len(values) <= MAX_INPUT_LENGTH
        or any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values)
    ):
        return INVALID_RESULT, b""

    order, sample_count = values[:2]
    if (
        not 1 <= order <= MAX_ORDER
        or not 1 <= sample_count <= MAX_SAMPLE_COUNT
        or len(values) != 4 + 2 * order + sample_count
    ):
        return INVALID_RESULT, b""

    a_scaled = values[2 : 3 + order]
    b_scaled = values[3 + order : 4 + 2 * order]
    samples_scaled = values[4 + 2 * order :]
    if (
        not 500 <= a_scaled[0] <= 2000
        or any(not -500 <= value <= 2000 for value in a_scaled[1:])
        or any(not -500 <= value <= 500 for value in b_scaled)
        or any(not -1000 <= value <= 1000 for value in samples_scaled)
    ):
        return INVALID_RESULT, b""

    a_coeffs = [value / 1000.0 for value in a_scaled]
    b_coeffs = [value / 1000.0 for value in b_scaled]
    input_history = [0.0] * order
    output_history = [0.0] * order
    output_samples: list[float] = []
    for raw_sample in samples_scaled:
        sample = raw_sample / 1000.0
        result = 0.0
        for i in range(1, order + 1):
            result += b_coeffs[i] * input_history[i - 1] - a_coeffs[i] * output_history[i - 1]
        result = (result + b_coeffs[0] * sample) / a_coeffs[0]

        for i in range(order - 1, 0, -1):
            input_history[i] = input_history[i - 1]
            output_history[i] = output_history[i - 1]
        input_history[0] = sample
        output_history[0] = result
        output_samples.append(result)

    output = b"".join(struct.pack("<d", sample) for sample in output_samples)
    if output_capacity is not None:
        if type(output_capacity) is not int or output_capacity < 0:
            return INVALID_RESULT, b""
        if output_capacity < len(output):
            return CAPACITY_ERROR_RESULT, b""
    return len(output), output
