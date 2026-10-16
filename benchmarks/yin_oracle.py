"""Source-order oracle for the pinned Rust YIN pitch detector."""

from __future__ import annotations
import math

MAX_SAMPLES = 256
MAX_LAG = 64
MAX_SAMPLE_RATE = 192_000
MIN_SAMPLE_VALUE = -32_768
MAX_SAMPLE_VALUE = 32_767
INVALID_RESULT = -1e300
I64_MIN, I64_MAX = -(2**63), 2**63 - 1


def expected_result(values: list[int] | tuple[int, ...]) -> float:
    if (not isinstance(values, (list, tuple)) or len(values) < 7
            or any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values)):
        return INVALID_RESULT
    count, sample_rate, min_frequency, max_frequency, threshold_micro = values[:5]
    if not 2 <= count <= MAX_SAMPLES or len(values) != count + 5:
        return INVALID_RESULT
    if not 1 <= sample_rate <= MAX_SAMPLE_RATE:
        return INVALID_RESULT
    if not (1 <= min_frequency < max_frequency <= sample_rate // 2):
        return INVALID_RESULT
    if not 1 <= threshold_micro <= 999_999:
        return INVALID_RESULT
    samples = values[5:]
    if any(not MIN_SAMPLE_VALUE <= sample <= MAX_SAMPLE_VALUE for sample in samples):
        return INVALID_RESULT
    min_lag = sample_rate // max_frequency
    max_lag = sample_rate // min_frequency
    if not (1 <= min_lag <= max_lag <= min(MAX_LAG, count - 1)):
        return INVALID_RESULT

    difference = [0.0] * (max_lag + 1)
    for lag in range(1, max_lag + 1):
        total = 0.0
        for index in range(count - lag):
            delta = float(samples[index]) - float(samples[index + lag])
            total += delta * delta
        difference[lag] = total
    cmndf = [0.0] * (max_lag + 1)
    cmndf[0] = 1.0
    total = 0.0
    for lag in range(1, max_lag + 1):
        total += difference[lag]
        cmndf[lag] = lag * difference[lag] / (1e-10 if total == 0.0 else total)
    threshold = threshold_micro / 1_000_000.0
    lag = min_lag
    while lag <= max_lag:
        if cmndf[lag] < threshold:
            while lag < max_lag and cmndf[lag + 1] < cmndf[lag]:
                lag += 1
            x0 = max(0, lag - 1)
            x2 = min(max_lag, lag + 1)
            s0, s1, s2 = cmndf[x0], cmndf[lag], cmndf[x2]
            denominator = s0 - 2.0 * s1 + s2
            refined_lag = float(lag) if denominator == 0.0 else lag + (s0 - s2) / (2.0 * denominator)
            if refined_lag <= 0.0 or not math.isfinite(refined_lag):
                return INVALID_RESULT
            return sample_rate / refined_lag
        lag += 1
    return INVALID_RESULT
