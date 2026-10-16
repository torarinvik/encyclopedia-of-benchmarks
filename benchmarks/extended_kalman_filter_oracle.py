"""Bounded 2-state nonlinear extended Kalman predict/update trace."""
from __future__ import annotations

INVALID_RESULT = -1.0e300
SCALE = 1000
MAX_STEPS = 8
MAX_INPUT_LENGTH = 9 + MAX_STEPS


def expected_result(values: tuple[int, ...] | list[int]) -> float:
    if len(values) < 10 or len(values) > MAX_INPUT_LENGTH:
        return INVALID_RESULT
    steps = values[0]
    if steps < 1 or steps > MAX_STEPS or len(values) != 9 + steps:
        return INVALID_RESULT
    x, y, p00, p01, p11, q0, q1, noise = (v / SCALE for v in values[1:9])
    if abs(values[1]) > 2000 or abs(values[2]) > 2000:
        return INVALID_RESULT
    if abs(values[3]) > 10000 or abs(values[4]) > 10000 or abs(values[5]) > 10000:
        return INVALID_RESULT
    if p00 <= 0 or p11 <= 0 or p00 * p11 <= p01 * p01:
        return INVALID_RESULT
    if q0 < 0 or q1 < 0 or noise <= 0 or noise > 10:
        return INVALID_RESULT
    if any(abs(z) > 10000 for z in values[9:]):
        return INVALID_RESULT

    for raw_z in values[9:]:
        # Nonlinear constant-acceleration-like transition and its Jacobian.
        f01 = 0.1
        f10 = 0.1 * x
        px = x + f01 * y
        py = y + 0.05 * x * x
        a = p00 + 2.0 * f01 * p01 + f01 * f01 * p11 + q0
        b = f10 * p00 + (1.0 + f01 * f10) * p01 + f01 * p11
        c = f10 * f10 * p00 + 2.0 * f10 * p01 + p11 + q1
        x, y, p00, p01, p11 = px, py, a, b, c

        h0 = 0.1 * x
        expected = 0.05 * x * x + y
        residual = raw_z / SCALE - expected
        innovation_covariance = h0 * h0 * p00 + 2.0 * h0 * p01 + p11 + noise
        k0 = (p00 * h0 + p01) / innovation_covariance
        k1 = (p01 * h0 + p11) / innovation_covariance
        x += k0 * residual
        y += k1 * residual

        # Joseph covariance update: A P A' + K R K', A=I-KH.
        a00 = 1.0 - k0 * h0
        a01 = -k0
        a10 = -k1 * h0
        a11 = 1.0 - k1
        n00 = a00 * a00 * p00 + 2.0 * a00 * a01 * p01 + a01 * a01 * p11 + k0 * k0 * noise
        n01 = a00 * a10 * p00 + (a00 * a11 + a01 * a10) * p01 + a01 * a11 * p11 + k0 * k1 * noise
        n11 = a10 * a10 * p00 + 2.0 * a10 * a11 * p01 + a11 * a11 * p11 + k1 * k1 * noise
        p00, p01, p11 = n00, n01, n11
    return x
