"""Independent scalar two-state unscented Kalman filter trace oracle."""
from __future__ import annotations

from math import sqrt

INVALID_RESULT = -1.0e300
SCALE = 1000
MAX_STEPS = 8


def _sigma_points(x: float, y: float, p00: float, p01: float, p11: float) -> list[tuple[float, float]] | None:
    """Return the five lower-Cholesky sigma points for alpha=1, kappa=0."""
    l00 = sqrt(2.0 * p00)
    l10 = (2.0 * p01) / l00
    remainder = 2.0 * p11 - l10 * l10
    if not (l00 > 0.0 and remainder > 0.0):
        return None
    l11 = sqrt(remainder)
    return [
        (x, y),
        (x + l00, y + l10),
        (x, y + l11),
        (x - l00, y - l10),
        (x, y - l11),
    ]


def _weighted_mean(points: list[tuple[float, float]]) -> tuple[float, float]:
    # lambda=0 gives mean weights [0, 1/4, 1/4, 1/4, 1/4].
    return (
        0.25 * points[1][0] + 0.25 * points[2][0] + 0.25 * points[3][0] + 0.25 * points[4][0],
        0.25 * points[1][1] + 0.25 * points[2][1] + 0.25 * points[3][1] + 0.25 * points[4][1],
    )


def _weighted_covariance(points: list[tuple[float, float]], mean: tuple[float, float]) -> tuple[float, float, float]:
    # The central covariance weight is 2; the four remaining weights are 1/4.
    weights = (2.0, 0.25, 0.25, 0.25, 0.25)
    p00 = p01 = p11 = 0.0
    for weight, (px, py) in zip(weights, points):
        dx, dy = px - mean[0], py - mean[1]
        p00 += weight * dx * dx
        p01 += weight * dx * dy
        p11 += weight * dy * dy
    return p00, p01, p11


def expected_result(values: tuple[int, ...] | list[int]) -> float:
    if len(values) < 10 or len(values) > 9 + MAX_STEPS:
        return INVALID_RESULT
    steps = values[0]
    if steps < 1 or steps > MAX_STEPS or len(values) != 9 + steps:
        return INVALID_RESULT

    x_raw, y_raw, p00_raw, p01_raw, p11_raw, q0_raw, q1_raw, r_raw = values[1:9]
    if abs(x_raw) > 1000 or abs(y_raw) > 1000:
        return INVALID_RESULT
    if not (500 <= p00_raw <= 1000 and 500 <= p11_raw <= 1000 and -100 <= p01_raw <= 100):
        return INVALID_RESULT
    if not (10 <= q0_raw <= 50 and 10 <= q1_raw <= 50 and 10 <= r_raw <= 100):
        return INVALID_RESULT
    if any(abs(z_raw) > 2000 for z_raw in values[9:]):
        return INVALID_RESULT

    x, y, p00, p01, p11, q0, q1, noise = (v / SCALE for v in values[1:9])
    for raw_z in values[9:]:
        sigma = _sigma_points(x, y, p00, p01, p11)
        if sigma is None:
            return INVALID_RESULT
        transformed = [(sx + 0.1 * sy, sy + 0.05 * sx * sx) for sx, sy in sigma]
        mean = _weighted_mean(transformed)
        p00, p01, p11 = _weighted_covariance(transformed, mean)
        p00 += q0
        p11 += q1
        p01 = 0.5 * (p01 + p01)
        x, y = mean

        sigma = _sigma_points(x, y, p00, p01, p11)
        if sigma is None:
            return INVALID_RESULT
        mapped = [0.05 * sx * sx + sy for sx, sy in sigma]
        expected_measurement = 0.25 * mapped[1] + 0.25 * mapped[2] + 0.25 * mapped[3] + 0.25 * mapped[4]
        innovation = noise
        cross0 = cross1 = 0.0
        for index, (sx, sy) in enumerate(sigma):
            dx, dy = sx - x, sy - y
            dz = mapped[index] - expected_measurement
            weight = 2.0 if index == 0 else 0.25
            innovation += weight * dz * dz
            cross0 += weight * dx * dz
            cross1 += weight * dy * dz
        if not (innovation > 0.0):
            return INVALID_RESULT
        k0, k1 = cross0 / innovation, cross1 / innovation
        residual = raw_z / SCALE - expected_measurement
        x += k0 * residual
        y += k1 * residual

        # Scalar specialization of P - K S K^T, with its off-diagonal symmetrized.
        u0, u1 = k0 * innovation, k1 * innovation
        p00 = p00 - u0 * k0
        p01 = p01 - 0.5 * (u0 * k1 + u1 * k0)
        p11 = p11 - u1 * k1
    return x
