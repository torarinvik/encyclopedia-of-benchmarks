"""Oracle for the bounded numerical Laplace transform benchmark."""

from __future__ import annotations

import math

MAX_SAMPLE_COUNT = 64
MAX_PARSEABLE_INPUT_LENGTH = MAX_SAMPLE_COUNT + 4
MAX_S_MILLI = 1_000
MAX_DT_MICRO = 1_000_000
MIN_SAMPLE_MICRO = -1_000_000
MAX_SAMPLE_MICRO = 1_000_000
INVALID_RESULT = -1.0e300


def expected_result(values: list[int]) -> float:
    if (not isinstance(values, list) or not 3 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
            or any(type(value) is not int or not -(2**63) <= value <= 2**63 - 1
                   for value in values)):
        return INVALID_RESULT

    sample_count, s_milli, dt_micro = values[:3]
    if not 1 <= sample_count <= MAX_SAMPLE_COUNT:
        return INVALID_RESULT
    if len(values) != sample_count + 3:
        return INVALID_RESULT
    if not 0 <= s_milli <= MAX_S_MILLI or not 1 <= dt_micro <= MAX_DT_MICRO:
        return INVALID_RESULT

    samples_micro = values[3:]
    if any(not MIN_SAMPLE_MICRO <= value <= MAX_SAMPLE_MICRO for value in samples_micro):
        return INVALID_RESULT

    s_value = s_milli / 1000.0
    delta_t = dt_micro / 1_000_000.0
    function_values = [value / 1_000_000.0 for value in samples_micro]
    if sample_count == 1:
        return 0.0

    stop = (sample_count - 1) * delta_t
    step = stop / (sample_count - 1)
    time_values = [index * step for index in range(sample_count)]
    time_values[-1] = stop
    integrand = [value * math.exp(-s_value * time_value)
                 for value, time_value in zip(function_values, time_values)]

    result = 0.0
    for index in range(sample_count - 1):
        result += (delta_t * (integrand[index] + integrand[index + 1])) / 2.0
    return result
