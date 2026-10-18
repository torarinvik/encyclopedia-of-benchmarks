"""Source-order oracle for the bounded realtime-statistics benchmark."""

from __future__ import annotations

import math
import struct

INVALID_RESULT = -1e300
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1
MAX_SAMPLES = 32
MAX_PARSEABLE_INPUT_LENGTH = 36
MIN_SAMPLE_Q = -64
MAX_SAMPLE_Q = 64


def _f32(value: float) -> float:
    """Round one operation result to IEEE-754 binary32."""
    return struct.unpack("<f", struct.pack("<f", value))[0]


def expected_result(values: list[int] | tuple[int, ...]) -> float:
    """Return the selected mean, variance, or standard deviation.

    Input words are ``[variant, statistic, count, q...]``. Each q represents
    the exact sample q/16. Variants 0 and 1 reproduce the C float32 operations;
    variant 2 reproduces the C++ ``stats_computer2<float>`` double accumulator.
    """
    if not isinstance(values, (list, tuple)) or len(values) > MAX_PARSEABLE_INPUT_LENGTH:
        return INVALID_RESULT
    if (len(values) < 3 or any(type(value) is not int or not I64_MIN <= value <= I64_MAX
                               for value in values)):
        return INVALID_RESULT

    variant, statistic, count = values[:3]
    if variant not in (0, 1, 2) or statistic not in (0, 1, 2):
        return INVALID_RESULT
    if not 2 <= count <= MAX_SAMPLES or len(values) != 3 + count:
        return INVALID_RESULT
    sample_words = values[3:]
    if any(not MIN_SAMPLE_Q <= value <= MAX_SAMPLE_Q for value in sample_words):
        return INVALID_RESULT

    samples = [_f32(value / 16.0) for value in sample_words]
    if variant == 0:
        # stats_computer1: first sample anchors K; every state update is float.
        anchor = samples[0]
        ex = 0.0
        ex2 = 0.0
        n = 0
        for sample in samples:
            n += 1
            delta = _f32(sample - anchor)
            ex = _f32(ex + delta)
            ex2 = _f32(ex2 + _f32(delta * delta))
        n32 = _f32(float(n))
        mean = _f32(anchor + _f32(ex / n32))
        correction = _f32(_f32(ex * ex) / n32)
        variance = _f32(_f32(ex2 - correction) / _f32(float(n - 1)))
        if statistic == 0:
            return mean
        if statistic == 1:
            return variance
        return _f32(math.sqrt(variance)) if variance >= 0.0 else math.nan

    if variant == 1:
        # stats_computer2 in C: Welford state and each intermediate are float.
        mu = 0.0
        m = 0.0
        n = 0
        for sample in samples:
            n += 1
            n32 = _f32(float(n))
            delta = _f32(sample - mu)
            mu = _f32(mu + _f32(delta / n32))
            delta2 = _f32(sample - mu)
            m = _f32(m + _f32(delta * delta2))
        variance = _f32(m / _f32(float(n)))
        if statistic == 0:
            return mu
        if statistic == 1:
            return variance
        return _f32(math.sqrt(variance)) if variance >= 0.0 else math.nan

    # stats_computer2<float> in C++: inputs are float32, Welford state is double.
    mu = 0.0
    m = 0.0
    n = 0
    for sample in samples:
        n += 1
        delta = float(sample) - mu
        mu += delta / n
        delta2 = float(sample) - mu
        m += delta * delta2
    variance = m / n
    if statistic == 0:
        return mu
    if statistic == 1:
        return variance
    return math.sqrt(variance) if variance >= 0.0 else math.nan
