"""Independent oracle for one bounded RSBench Doppler cross-section lookup."""
from __future__ import annotations

from collections.abc import Sequence
import math

INVALID_RESULT = -1e300
SCALE = 1_000_000.0
MAX_WINDOWS = 4
MAX_POLES = 8
MAX_L = 4
MAX_INPUT_LENGTH = 100
POLE_LIMIT = 152_500_000

Complex = tuple[float, float]


def _add(a: Complex, b: Complex) -> Complex:
    return a[0] + b[0], a[1] + b[1]


def _sub(a: Complex, b: Complex) -> Complex:
    return a[0] - b[0], a[1] - b[1]


def _scale(a: Complex, factor: float) -> Complex:
    return a[0] * factor, a[1] * factor


def _mul(a: Complex, b: Complex) -> Complex:
    return a[0] * b[0] - a[1] * b[1], a[0] * b[1] + a[1] * b[0]


def _div(a: Complex, b: Complex) -> Complex:
    denominator = b[0] * b[0] + b[1] * b[1]
    return ((a[0] * b[0] + a[1] * b[1]) / denominator,
            (a[1] * b[0] - a[0] * b[1]) / denominator)


def _fast_nuclear_w(z: Complex) -> Complex:
    an = (2.758402e-01, 2.245740e-01, 1.594149e-01, 9.866577e-02, 5.324414e-02,
          2.505215e-02, 1.027747e-02, 3.676164e-03, 1.146494e-03, 3.117570e-04)
    signs = (-1.0, 1.0, -1.0, 1.0, -1.0, 1.0, -1.0, 1.0, -1.0, 1.0)
    denominator_left = (9.869604e+00, 3.947842e+01, 8.882644e+01, 1.579137e+02,
                        2.467401e+02, 3.553058e+02, 4.836106e+02, 6.316547e+02,
                        7.994380e+02, 9.869604e+02)
    if math.sqrt(z[0] * z[0] + z[1] * z[1]) < 6.0:
        magnitude = math.exp(-12.0 * z[1])
        angle = 12.0 * z[0]
        e = magnitude * math.cos(angle), magnitude * math.sin(angle)
        w = _div(_mul((0.0, 1.0), _sub((1.0, 0.0), e)), _scale(z, 12.0))
        total = (0.0, 0.0)
        for n in range(10):
            top = _sub(_scale(e, signs[n]), (1.0, 0.0))
            z2_scaled = _mul(_scale(z, 144.0), z)
            bottom = _sub((denominator_left[n], 0.0), z2_scaled)
            total = _add(total, _scale(_div(top, bottom), an[n]))
        return _add(w, _mul(_mul((0.0, 8.124330e+01), z), total))

    a = 0.512424224754768462984202823134979415014943561548661637413182
    b = 0.275255128608410950901357962647054304017026259671664935783653
    c = 0.051765358792987823963876628425793170829107067780337219430904
    d = 2.724744871391589049098642037352945695982973740328335064216346
    z2 = _mul(z, z)
    left = _div((a, 0.0), _sub(z2, (b, 0.0)))
    right = _div((c, 0.0), _sub(z2, (d, 0.0)))
    return _mul(_mul((0.0, 1.0), z), _add(left, right))


def expected_result(values: Sequence[int] | None, *, input_is_null: bool = False,
                    input_length: int | None = None) -> float:
    if type(input_is_null) is not bool:
        return INVALID_RESULT
    if input_is_null or values is None or not isinstance(values, (list, tuple)):
        return INVALID_RESULT
    if not 10 <= len(values) <= MAX_INPUT_LENGTH:
        return INVALID_RESULT
    if input_length is not None and (type(input_length) is not int or input_length != len(values)):
        return INVALID_RESULT
    if any(type(value) is not int or not -(2**63) <= value < 2**63 for value in values):
        return INVALID_RESULT

    nwin, npole, nl, energy_raw = values[:4]
    if not 1 <= nwin <= MAX_WINDOWS or not 0 <= npole <= MAX_POLES or not 1 <= nl <= MAX_L:
        return INVALID_RESULT
    if not 0 <= energy_raw <= 1_000_000:
        return INVALID_RESULT
    factor_base = 4 + nwin * 5
    pole_base = factor_base + nl
    if len(values) != pole_base + npole * 9:
        return INVALID_RESULT

    windows: list[tuple[float, float, float, int, int]] = []
    for index in range(nwin):
        t_raw, a_raw, f_raw, start, end = values[4 + index * 5:9 + index * 5]
        if not (0 <= t_raw <= 1_000_000 and 0 <= a_raw <= 1_000_000 and 0 <= f_raw <= 1_000_000):
            return INVALID_RESULT
        if not (0 <= start <= end <= npole):
            return INVALID_RESULT
        windows.append((t_raw / SCALE, a_raw / SCALE, f_raw / SCALE, start, end))
    pseudo_raw = values[factor_base:pole_base]
    if any(value < 0 or value > 1_000_000 for value in pseudo_raw):
        return INVALID_RESULT
    poles: list[tuple[Complex, Complex, Complex, Complex, int]] = []
    for index in range(npole):
        fields = values[pole_base + index * 9:pole_base + index * 9 + 9]
        if any(value < 0 or value > POLE_LIMIT for value in fields[:8]):
            return INVALID_RESULT
        if not 0 <= fields[8] < nl:
            return INVALID_RESULT
        poles.append(((fields[0] / SCALE, fields[1] / SCALE),
                      (fields[2] / SCALE, fields[3] / SCALE),
                      (fields[4] / SCALE, fields[5] / SCALE),
                      (fields[6] / SCALE, fields[7] / SCALE), fields[8]))

    energy = energy_raw / SCALE
    spacing = 1.0 / nwin
    window = int(energy / spacing)
    if window == nwin:
        window -= 1
    if not 0 <= window < nwin:
        return INVALID_RESULT

    root_energy = math.sqrt(energy)
    factors: list[Complex] = []
    for i, raw in enumerate(pseudo_raw):
        phi = (raw / SCALE) * root_energy
        if i == 1:
            phi -= -math.atan(phi)
        elif i == 2:
            phi -= math.atan(3.0 * phi / (3.0 - phi * phi))
        elif i == 3:
            phi -= math.atan(phi * (15.0 - phi * phi) / (15.0 - 6.0 * phi * phi))
        phi *= 2.0
        factors.append((math.cos(phi), -math.sin(phi)))

    bg_t, bg_a, bg_f, first, last = windows[window]
    sig_t = energy * bg_t
    sig_a = energy * bg_a
    sig_f = energy * bg_f
    for pole_id in range(first, last):
        ea, rt, ra, rf, l_value = poles[pole_id]
        z = _scale(_sub((energy, 0.0), ea), 0.5)
        if z == (0.0, 0.0):
            return INVALID_RESULT
        try:
            faddeeva = _fast_nuclear_w(z)
        except (OverflowError, ZeroDivisionError, ValueError):
            # The source approximation is singular for an exact Z=0 pole;
            # represent the resulting non-finite native result uniformly.
            return INVALID_RESULT
        sig_t += _mul(_mul(rt, faddeeva), factors[l_value])[0]
        sig_a += _mul(ra, faddeeva)[0]
        sig_f += _mul(rf, faddeeva)[0]
    sig_e = sig_t - sig_a
    result = sig_t + 2.0 * sig_a + 3.0 * sig_f + 5.0 * sig_e
    return result if math.isfinite(result) else INVALID_RESULT


oracle = expected_result
