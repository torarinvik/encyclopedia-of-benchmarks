"""Independent oracle for the bounded Butterworth biquad-coefficient ABI."""

from __future__ import annotations

from math import cos, pow, sin, sqrt, tau

INVALID_RESULT = -1e300
MAX_SAMPLE_RATE = 192_000
MAX_FREQUENCY = 95_999
MAX_Q_MICRO = 10_000_000
MAX_GAIN_MILLI_DB = 60_000
DEFAULT_Q_FACTOR = 1.0 / sqrt(2.0)


def expected_result(values: list[int]) -> float:
    """Return one selected biquad coefficient, or the invalid-input sentinel."""
    if (not isinstance(values, list) or len(values) != 6
            or any(type(value) is not int for value in values)):
        return INVALID_RESULT
    filter_kind, coefficient_index, frequency, samplerate, gain_milli, q_micro = values
    if not 0 <= filter_kind <= 8 or not 0 <= coefficient_index <= 5:
        return INVALID_RESULT
    if not 1 <= frequency <= MAX_FREQUENCY or not 1 <= samplerate <= MAX_SAMPLE_RATE:
        return INVALID_RESULT
    if 2 * frequency >= samplerate:
        return INVALID_RESULT
    if q_micro == -1:
        q_factor = DEFAULT_Q_FACTOR
    elif 1 <= q_micro <= MAX_Q_MICRO:
        q_factor = q_micro / 1_000_000.0
    else:
        return INVALID_RESULT
    needs_gain = filter_kind in (4, 5, 6)
    if needs_gain:
        if not -MAX_GAIN_MILLI_DB <= gain_milli <= MAX_GAIN_MILLI_DB:
            return INVALID_RESULT
        gain_db = gain_milli / 1000.0
    else:
        if gain_milli != 0:
            return INVALID_RESULT
        gain_db = 0.0

    w0 = tau * frequency / samplerate
    sine = sin(w0)
    cosine = cos(w0)
    alpha = sine / (2.0 * q_factor)
    a0 = 1.0 + alpha
    a1 = -2.0 * cosine
    a2 = 1.0 - alpha

    if filter_kind == 0:  # make_lowpass
        b0 = (1.0 - cosine) / 2.0
        b1 = 1.0 - cosine
        b2 = b0
    elif filter_kind == 1:  # make_highpass
        b0 = (1.0 + cosine) / 2.0
        b1 = -1.0 - cosine
        b2 = b0
    elif filter_kind == 2:  # make_bandpass
        b0 = sine / 2.0
        b1 = 0.0
        b2 = -b0
    elif filter_kind == 3:  # make_allpass
        b0 = 1.0 - alpha
        b1 = -2.0 * cosine
        b2 = 1.0 + alpha
        a0, a1, a2 = b2, b1, b0
    elif filter_kind == 4:  # make_peak
        big_a = pow(10.0, gain_db / 40.0)
        b0 = 1.0 + alpha * big_a
        b1 = -2.0 * cosine
        b2 = 1.0 - alpha * big_a
        a0 = 1.0 + alpha / big_a
        a1 = -2.0 * cosine
        a2 = 1.0 - alpha / big_a
    elif filter_kind in (5, 6):  # make_lowshelf / make_highshelf
        big_a = pow(10.0, gain_db / 40.0)
        plus_minus_cosine = (big_a + 1.0) - (big_a - 1.0) * cosine
        plus_plus_cosine = (big_a + 1.0) + (big_a - 1.0) * cosine
        minus_plus_cosine = (big_a - 1.0) - (big_a + 1.0) * cosine
        plus_minus_sine = (big_a - 1.0) + (big_a + 1.0) * cosine
        aa2 = 2.0 * sqrt(big_a) * alpha
        if filter_kind == 5:
            b0 = big_a * (plus_minus_cosine + aa2)
            b1 = 2.0 * big_a * minus_plus_cosine
            b2 = big_a * (plus_minus_cosine - aa2)
            a0 = plus_plus_cosine + aa2
            a1 = -2.0 * plus_minus_sine
            a2 = plus_plus_cosine - aa2
        else:
            b0 = big_a * (plus_plus_cosine + aa2)
            b1 = -2.0 * big_a * plus_minus_sine
            b2 = big_a * (plus_plus_cosine - aa2)
            a0 = plus_minus_cosine + aa2
            a1 = 2.0 * minus_plus_cosine
            a2 = plus_minus_cosine - aa2
    elif filter_kind == 7:  # make_notch
        b0 = 1.0
        b1 = -2.0 * cosine
        b2 = 1.0
    else:  # make_bandpass_peak
        b0 = alpha
        b1 = 0.0
        b2 = -alpha

    return (a0, a1, a2, b0, b1, b2)[coefficient_index]
