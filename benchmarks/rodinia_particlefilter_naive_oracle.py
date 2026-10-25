"""Independent deterministic one-transition model of Rodinia particlefilter_naive."""

from __future__ import annotations

import math
from collections.abc import Sequence

INVALID_RESULT = -1
SCALE = 1_000_000
MAX_PARTICLES = 4
MAX_SAMPLES = 4


def _round_away(value: float) -> int:
    scaled = value * 1_000.0
    return math.floor(scaled + 0.5) if scaled >= 0 else -math.floor(-scaled + 0.5)


def expected_result(values: Sequence[int] | None) -> int:
    if (not isinstance(values, (tuple, list)) or len(values) < 8
            or any(type(value) is not int for value in values)):
        return INVALID_RESULT
    count, sample_count, offset_raw = values[:3]
    if not (1 <= count <= MAX_PARTICLES and 1 <= sample_count <= MAX_SAMPLES):
        return INVALID_RESULT
    if offset_raw < 0 or offset_raw >= SCALE or offset_raw * count >= SCALE:
        return INVALID_RESULT
    if len(values) != 3 + count * (4 + sample_count):
        return INVALID_RESULT

    x: list[float] = []
    y: list[float] = []
    moved_x: list[float] = []
    moved_y: list[float] = []
    likelihood: list[float] = []
    weight: list[float] = []
    for particle in range(count):
        start = 3 + particle * (4 + sample_count)
        x_raw, y_raw, normal_x_raw, normal_y_raw = values[start:start + 4]
        if not (-100 * SCALE <= x_raw <= 100 * SCALE and -100 * SCALE <= y_raw <= 100 * SCALE
                and -2 * SCALE <= normal_x_raw <= 2 * SCALE and -2 * SCALE <= normal_y_raw <= 2 * SCALE):
            return INVALID_RESULT
        samples = values[start + 4:start + 4 + sample_count]
        if any(sample < 0 or sample > 255 for sample in samples):
            return INVALID_RESULT

        px = x_raw / SCALE
        py = y_raw / SCALE
        nx = normal_x_raw / SCALE
        ny = normal_y_raw / SCALE
        # Source applies the constant drift, then scaled Box-Muller draws.
        mx = px + 1.0 + 5.0 * nx
        my = py - 2.0 + 2.0 * ny
        # The source's roundDouble returns newValue++ (post-increment), hence
        # the expression returns the pre-increment truncation. Pixel indexing
        # is outside this profile, but the quirk is documented for the source.
        log_ratio = 0.0
        for intensity in samples:
            foreground = float(intensity - 100)
            background = float(intensity - 228)
            log_ratio += (foreground * foreground - background * background) / 50.0
        log_likelihood = log_ratio / sample_count
        x.append(px)
        y.append(py)
        moved_x.append(mx)
        moved_y.append(my)
        likelihood.append(log_likelihood)
        weight.append((1.0 / count) * math.exp(log_likelihood))

    weight_sum = 0.0
    for item in weight:
        weight_sum += item
    if not math.isfinite(weight_sum) or weight_sum <= 0.0:
        return INVALID_RESULT
    for particle in range(count):
        weight[particle] /= weight_sum

    estimate_x = 0.0
    estimate_y = 0.0
    for particle in range(count):
        estimate_x += moved_x[particle] * weight[particle]
        estimate_y += moved_y[particle] * weight[particle]

    cdf = [weight[0]]
    for particle in range(1, count):
        cdf.append(weight[particle] + cdf[particle - 1])
    offset = offset_raw / SCALE
    selected_x: list[float] = []
    selected_y: list[float] = []
    for particle in range(count):
        u = offset + particle / count
        selected = count - 1
        for index in range(count):
            if cdf[index] >= u:
                selected = index
                break
        selected_x.append(moved_x[selected])
        selected_y.append(moved_y[selected])

    checksum = _round_away(estimate_x) + 2 * _round_away(estimate_y)
    for particle in range(count):
        checksum += (2 * particle + 3) * _round_away(selected_x[particle])
        checksum += (2 * particle + 4) * _round_away(selected_y[particle])
    return checksum
