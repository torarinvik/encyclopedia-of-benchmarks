"""Independent model for the bounded LAME analysis-window subband stage."""

from __future__ import annotations

import math
from collections.abc import Sequence

SAMPLE_COUNT = 511
WINDOW_COUNT = 256
INPUT_COUNT = SAMPLE_COUNT + WINDOW_COUNT
MAX_INPUT_LENGTH = INPUT_COUNT + 1
BAND_COUNT = 32
OUTPUT_SCALE = 1000
MAX_OUTPUT_BYTES = BAND_COUNT * 8
INVALID_RESULT = -1
OUTPUT_ERROR = -2
PI = 3.14159265358979323846264338327950288
SAMPLE_MIN = -32768
SAMPLE_MAX = 32767
WINDOW_MIN_SCALED = -4_500_000
WINDOW_MAX_SCALED = 36_000_000
DENOMINATOR_MIN_SCALED = 25_000_000

S_OFFSETS = (334, 398, 462, 14, 78, 142, 206, 16, 80, 144, 208, 272, 336, 400, 464)
T_OFFSETS = (176, 112, 48, 496, 432, 368, 304, 494, 430, 366, 302, 238, 174, 110, 46)


def _valid(values: Sequence[int], input_is_null: bool = False,
           input_length: int | None = None) -> bool:
    if type(input_is_null) is not bool or input_is_null:
        return False
    if not isinstance(values, (tuple, list)):
        return False
    length = len(values) if input_length is None else input_length
    if type(length) is not int or length != INPUT_COUNT or len(values) != INPUT_COUNT:
        return False
    if any(type(value) is not int for value in values):
        return False
    samples = values[:SAMPLE_COUNT]
    coeffs = values[SAMPLE_COUNT:]
    if any(not SAMPLE_MIN <= value <= SAMPLE_MAX for value in samples):
        return False
    if any(not WINDOW_MIN_SCALED <= value <= WINDOW_MAX_SCALED for value in coeffs):
        return False
    return all(coeffs[index] > DENOMINATOR_MIN_SCALED
               for index in (0, *range(8, WINDOW_COUNT, 16)))


def _build_tables(coefficients_scaled: Sequence[int]) -> tuple[list[float], list[float], list[list[float]]]:
    window = [value / 1_000_000_000.0 for value in coefficients_scaled]
    maximum = window[248]
    mmax = [0.0] * 31
    source = 0
    target = 0
    weight = window[source]
    source += 1
    mmax[15] = weight / maximum
    for _ in range(7):
        window[target] = window[source] / weight
        target += 1
        source += 1
    for i in range(14, -1, -1):
        weight = window[source]
        source += 1
        mmax[i] = weight / maximum
        mmax[30 - i] = weight / maximum
        for _ in range(15):
            window[target] = window[source] / weight
            target += 1
            source += 1
    source += 1
    for _ in range(7):
        window[target] = window[source] / maximum
        target += 1
        source += 1
    mm = [[0.0] * 31 for _ in range(16)]
    for i in range(15, -1, -1):
        for k in range(1, 32):
            angle = (2 * i + 1) * k * PI / 64.0
            mm[i][k - 1] = math.cos(angle) * mmax[k - 1]
    return window, mmax, mm


def calculate(values: Sequence[int]) -> tuple[int, ...]:
    """Run one source-order 512-tap analysis window and return Q1000 bands."""
    samples = values[:SAMPLE_COUNT]
    window, _mmax, mm = _build_tables(values[SAMPLE_COUNT:])
    inner = [0.0] * 31
    coeff = 0

    # Central term plus the seven alternating symmetric tap pairs.
    t = float(samples[255])
    pairs = ((223, 287, -1), (191, 319, 1), (159, 351, -1),
             (127, 383, 1), (95, 415, -1), (63, 447, 1), (31, 479, -1))
    for left, right, sign in pairs:
        delta = samples[left] + sign * samples[right]
        t += float(delta) * window[coeff]
        coeff += 1
    inner[15] = t

    for i in range(14, -1, -1):
        s = float(samples[270 - i])
        t = float(samples[240 + i])
        for k in range(15):
            weight = window[coeff]
            coeff += 1
            s_index = S_OFFSETS[k] + (-i if k < 7 else i)
            t_index = T_OFFSETS[k] + (i if k < 7 else -i)
            s_term = float(samples[s_index]) * weight
            t_term = float(samples[t_index]) * weight
            s = s - s_term if k >= 11 else s + s_term
            t = t - t_term if 7 <= k < 11 else t + t_term
        inner[30 - i] = s
        inner[i] = t

    s = float(samples[239])
    for index, sign in ((175, 1), (111, 1), (47, 1),
                        (303, -1), (367, -1), (431, -1), (495, -1)):
        term = float(samples[index]) * window[coeff]
        coeff += 1
        s = s + term if sign > 0 else s - term

    bands = [0.0] * BAND_COUNT
    for i in range(15, -1, -1):
        s0 = s
        s1 = t * mm[i][0]
        at = 1
        for _ in range(15):
            s0 += mm[i][at] * inner[at]
            at += 1
            s1 += mm[i][at] * inner[at]
            at += 1
        bands[i] = s0 + s1
        bands[31 - i] = s0 - s1
    projected = []
    for value in bands:
        scaled = value * OUTPUT_SCALE
        magnitude = math.floor(abs(scaled) + 0.5)
        projected.append(-magnitude if scaled < 0.0 else magnitude)
    return tuple(projected)


def expected_output(
    values: Sequence[int],
    capacity: int = MAX_OUTPUT_BYTES,
    output_is_null: bool = False,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> tuple[int, tuple[int, ...]]:
    if not _valid(values, input_is_null, input_length):
        return INVALID_RESULT, ()
    if type(capacity) is not int or capacity < 0 or type(output_is_null) is not bool:
        return INVALID_RESULT, ()
    if output_is_null or capacity < MAX_OUTPUT_BYTES:
        return OUTPUT_ERROR, ()
    return MAX_OUTPUT_BYTES, calculate(values)
