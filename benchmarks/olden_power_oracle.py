"""Independent oracle for the bounded Olden power pricing recurrence."""

from __future__ import annotations

from math import floor, sqrt

MAX_LEAVES = 4
MAX_COMPUTE_PASSES = 4
MAX_INPUT_LENGTH = 2
FIXED_POINT_SCALE = 1_000
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1
INVALID_RESULT = -1


def _find_g(p: float, q: float) -> float:
    return p * p + q * q - 0.8


def _find_h(p: float, q: float) -> float:
    return p - 5.0 * q


def _gradient_f(p: float, q: float, pi_r: float, pi_i: float) -> tuple[float, tuple[float, float]]:
    gradient = [1.0 / (1.0 + p) - pi_r, 1.0 / (1.0 + q) - pi_i]
    magnitude = sqrt(gradient[0] * gradient[0] + gradient[1] * gradient[1])
    return magnitude, (gradient[0] / magnitude, gradient[1] / magnitude)


def _gradient_g(p: float, q: float) -> tuple[float, tuple[float, float]]:
    gradient = [2.0 * p, 2.0 * q]
    magnitude = sqrt(gradient[0] * gradient[0] + gradient[1] * gradient[1])
    return magnitude, (gradient[0] / magnitude, gradient[1] / magnitude)


def _gradient_h() -> tuple[float, float, float]:
    magnitude = sqrt(26.0)
    return magnitude, (1.0 / magnitude, -5.0 / magnitude)


def _second_gradient_f(p: float, q: float, pi_r: float, pi_i: float) -> tuple[float, float]:
    p_inv, q_inv = 1.0 / (p + 1.0), 1.0 / (q + 1.0)
    p_term, q_term = p_inv - pi_r, q_inv - pi_i
    magnitude = sqrt(p_term * p_term + q_term * q_term)
    return (-p_inv * p_inv * p_term / magnitude,
            -q_inv * q_inv * q_term / magnitude)


def _make_orthogonal(modified: tuple[float, float], fixed: tuple[float, float]) -> tuple[float, tuple[float, float]]:
    dot = modified[0] * fixed[0] + modified[1] * fixed[1]
    x = modified[0] - dot * fixed[0]
    y = modified[1] - dot * fixed[1]
    length = sqrt(x * x + y * y)
    result = (x / length, y / length)
    if 1.0 - dot * dot < 0.0:
        return 0.0, result
    return sqrt(1.0 - dot * dot), result


def _optimize_one(p: float, q: float, pi_r: float, pi_i: float) -> tuple[float, float]:
    h = _find_h(p, q)
    if abs(h) > 0.000001:
        magnitude, grad_h = _gradient_h()
        total = h / magnitude
        p -= total * grad_h[0]
        q -= total * grad_h[1]

    g = _find_g(p, q)
    if g > 0.000001:
        magnitude, grad_g = _gradient_g(p, q)
        _, grad_h = _gradient_h()
        orthogonal_scale, grad_g = _make_orthogonal(grad_g, grad_h)
        magnitude *= orthogonal_scale
        total = g / magnitude
        p -= total * grad_g[0]
        q -= total * grad_g[1]

    magnitude, grad_f = _gradient_f(p, q, pi_r, pi_i)
    dd_grad_f = _second_gradient_f(p, q, pi_r, pi_i)
    total = grad_f[0] * dd_grad_f[0] + grad_f[1] * dd_grad_f[1]
    magnitude /= abs(total)
    _, grad_h = _gradient_h()
    orthogonal_scale, grad_f = _make_orthogonal(grad_f, grad_h)
    magnitude *= orthogonal_scale
    _, grad_g = _gradient_g(p, q)
    total = grad_f[0] * grad_g[0] + grad_f[1] * grad_g[1]
    if total > 0.0:
        max_dist = -_find_g(p, q) / total
        if magnitude > max_dist:
            magnitude = max_dist
    return p + magnitude * grad_f[0], q + magnitude * grad_f[1]


def _solve_voltage(p: float, q: float, resistance: float, reactance: float) -> tuple[float, float, float, float]:
    a = resistance * resistance + reactance * reactance
    b = 2.0 * resistance * reactance * q - 2.0 * reactance * reactance * p - resistance
    c = resistance * q - reactance * p
    c = c * c + resistance * p
    root = (-b - sqrt(b * b - 4.0 * a * c)) / (2.0 * a)
    q += ((root - p) * reactance) / resistance
    p = root
    a = 2.0 * resistance * p
    b = 2.0 * reactance * q
    return p, q, a / (1.0 - a - b), b / (1.0 - a - b)


def _quantize(value: float) -> int:
    """Round a bounded state component to the nearest thousandth."""
    return floor(value * FIXED_POINT_SCALE + 0.5)


def expected_result(values: list[int] | tuple[int, ...] | None) -> int:
    """Return a fixed-point projection of final state plus optimizer-body count."""
    if (not isinstance(values, (list, tuple)) or len(values) != MAX_INPUT_LENGTH
            or any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values)):
        return INVALID_RESULT
    leaf_count, compute_passes = values
    if not 1 <= leaf_count <= MAX_LEAVES or not 0 <= compute_passes <= MAX_COMPUTE_PASSES:
        return INVALID_RESULT

    leaf_p = [1.0] * leaf_count
    leaf_q = [1.0] * leaf_count
    branch_alpha = branch_beta = lateral_alpha = lateral_beta = 0.0
    theta_r, theta_i = 0.8, 0.16
    work_count = 0
    for _ in range(compute_passes):
        lateral_pi_r = theta_r + lateral_alpha * (theta_r + (theta_i * 0.000001) / (1.0 / 300000.0))
        lateral_pi_i = theta_i + lateral_beta * (theta_i + (theta_r * (1.0 / 300000.0)) / 0.000001)
        branch_pi_r = lateral_pi_r + branch_alpha * (theta_r + (theta_i * 0.00002) / 0.0001)
        branch_pi_i = lateral_pi_i + branch_beta * (theta_i + (theta_r * 0.0001) / 0.00002)
        branch_p = branch_q = 0.0
        for leaf in range(leaf_count):
            leaf_p[leaf], leaf_q[leaf] = _optimize_one(
                leaf_p[leaf], leaf_q[leaf], branch_pi_r, branch_pi_i
            )
            if leaf_p[leaf] < 0.0:
                leaf_p[leaf] = leaf_q[leaf] = 0.0
            branch_p += leaf_p[leaf]
            branch_q += leaf_q[leaf]
            work_count += 1
        branch_p, branch_q, branch_alpha, branch_beta = _solve_voltage(
            branch_p, branch_q, 0.0001, 0.00002
        )
        _, _, lateral_alpha, lateral_beta = _solve_voltage(
            branch_p, branch_q, 1.0 / 300000.0, 0.000001
        )

    state_projection = sum(_quantize(p) + 2 * _quantize(q) for p, q in zip(leaf_p, leaf_q))
    state_projection += _quantize(branch_alpha) + 2 * _quantize(branch_beta)
    state_projection += _quantize(lateral_alpha) + 2 * _quantize(lateral_beta)
    return state_projection + work_count
