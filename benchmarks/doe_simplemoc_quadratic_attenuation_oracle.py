"""Oracle for one bounded SimpleMOC quadratic-source attenuation segment."""
from __future__ import annotations

from collections.abc import Sequence
import math
import struct

INVALID_RESULT = -1e300
FIXED_SCALE = 1_000_000
MAX_GROUPS = 4
HEADER_LENGTH = 7
GROUP_RECORD_LENGTH = 6
MAX_INPUT_LENGTH = HEADER_LENGTH + MAX_GROUPS * GROUP_RECORD_LENGTH
MAX_PARSEABLE_INPUT_LENGTH = MAX_INPUT_LENGTH + 1
MAX_FIXED_COMPONENT = 10_000_000
TABLE_INTERVALS = 353
TABLE_MAX = 10.0


def _f32(value: float) -> float:
    return struct.unpack("<f", struct.pack("<f", value))[0]


def _add(left: float, right: float) -> float:
    return _f32(_f32(left) + _f32(right))


def _sub(left: float, right: float) -> float:
    return _f32(_f32(left) - _f32(right))


def _mul(left: float, right: float) -> float:
    return _f32(_f32(left) * _f32(right))


def _div(left: float, right: float) -> float:
    return _f32(_f32(left) / _f32(right))


def _decode(raw: int) -> float:
    return _div(_f32(float(raw)), _f32(float(FIXED_SCALE)))


def _table_value(tau: float) -> float:
    dx = _f32(_f32(TABLE_MAX) / _f32(float(TABLE_INTERVALS)))
    max_value = _sub(_f32(TABLE_MAX), dx)
    if tau > max_value:
        return _f32(1.0)
    interval = int(_add(_div(tau, dx), _mul(_f32(0.5), dx)))
    if not 0 <= interval < TABLE_INTERVALS:
        return _f32(1.0)
    anchor = _mul(_f32(float(interval)), dx)
    exponential = _f32(math.exp(-anchor))
    slope = _f32(-exponential)
    intercept = _add(_f32(1.0), _mul(_sub(anchor, _f32(1.0)), exponential))
    return _add(_mul(slope, tau), intercept)


def expected_result(values: Sequence[int] | None, *, input_is_null: bool = False,
                    input_length: int | None = None) -> float:
    if (type(input_is_null) is not bool or input_is_null or values is None
            or not isinstance(values, (list, tuple))):
        return INVALID_RESULT
    if not HEADER_LENGTH <= len(values) <= MAX_INPUT_LENGTH:
        return INVALID_RESULT
    if input_length is not None and (
            type(input_length) is not int or input_length != len(values)):
        return INVALID_RESULT
    if any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
           for value in values):
        return INVALID_RESULT

    groups = values[0]
    if type(groups) is not int or not 1 <= groups <= MAX_GROUPS:
        return INVALID_RESULT
    if len(values) != HEADER_LENGTH + GROUP_RECORD_LENGTH * groups:
        return INVALID_RESULT
    if any(abs(value) > MAX_FIXED_COMPONENT for value in values[1:]):
        return INVALID_RESULT

    zin, dz, ds, mu, az_weight, polar_weight = map(_decode, values[1:7])
    if (dz < _f32(0.01) or dz > _f32(10.0) or ds < _f32(0.001)
            or ds > _f32(10.0) or abs(_mul(_f32(2.0), zin)) > dz
            or not 0.0 <= mu <= 1.0
            or not 0.0 <= az_weight <= 1.0
            or not 0.0 <= polar_weight <= 1.0):
        return INVALID_RESULT

    decoded_groups: list[tuple[float, float, float, float, float, float]] = []
    for group in range(groups):
        start = HEADER_LENGTH + GROUP_RECORD_LENGTH * group
        y1, y2, y3, sigma, psi, tally = map(
            _decode, values[start:start + GROUP_RECORD_LENGTH])
        if (sigma < _f32(0.1) or sigma > _f32(10.0)
                or psi < 0.0 or tally < 0.0):
            return INVALID_RESULT
        tau = _mul(sigma, ds)
        if tau <= 0.0 or tau > _f32(TABLE_MAX):
            return INVALID_RESULT
        decoded_groups.append((y1, y2, y3, sigma, psi, tally))

    weight = _mul(polar_weight, az_weight)
    mu2 = _mul(mu, mu)
    checksum = _f32(0.0)
    for group, (y1, y2, y3, sigma, psi, tally_in) in enumerate(decoded_groups):
        c1 = _div(_sub(y1, y3), _mul(_f32(2.0), dz))
        c2_numerator = _add(_sub(y1, _mul(_f32(2.0), y2)), y3)
        c2_denominator = _mul(_mul(_f32(2.0), dz), dz)
        c2 = _div(c2_numerator, c2_denominator)
        q0 = _add(_add(y2, _mul(c1, zin)), _mul(_mul(c2, zin), zin))
        q1 = _add(c1, _mul(_mul(_f32(2.0), c2), zin))
        q2 = c2

        tau = _mul(sigma, ds)
        exponential = _table_value(tau)
        sigma2 = _mul(sigma, sigma)
        reuse = _add(
            _mul(tau, _sub(tau, _f32(2.0))),
            _div(_mul(_f32(2.0), exponential), _mul(sigma, sigma2)),
        )
        source_linear = _mul(_sub(_mul(sigma, psi), q0), exponential)
        flux_integral = _div(_add(_mul(q0, tau), source_linear), sigma2)
        flux_integral = _add(flux_integral, _mul(_mul(q1, mu), reuse))
        quadratic_inner = _add(
            _mul(tau, _sub(tau, _f32(3.0))), _f32(6.0),
        )
        cubic = _sub(_mul(tau, quadratic_inner), _mul(_f32(6.0), exponential))
        cubic_term = _div(
            _mul(_mul(q2, mu2), cubic),
            _mul(_mul(_f32(3.0), sigma2), sigma2),
        )
        flux_integral = _add(flux_integral, cubic_term)
        tally_out = _add(tally_in, _mul(weight, flux_integral))

        t1 = _div(_mul(q0, exponential), sigma)
        t2 = _div(_mul(_mul(q1, mu), _sub(tau, exponential)), sigma2)
        t3 = _mul(_mul(q2, mu2), reuse)
        t4 = _mul(psi, _sub(_f32(1.0), exponential))
        psi_out = _add(_add(_add(t1, t2), t3), t4)

        group_sum = _add(tally_out, psi_out)
        checksum = _add(checksum, _mul(_f32(float(group + 1)), group_sum))

    return float(checksum)
