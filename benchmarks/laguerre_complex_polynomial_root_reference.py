"""Independent root-set reference using simultaneous Durand--Kerner updates."""

from __future__ import annotations

import math
from collections.abc import Sequence
from decimal import Decimal, localcontext


def _decode(values: Sequence[int | float]) -> tuple[int, list[float], complex, float, int] | None:
    if not isinstance(values, (list, tuple)) or not values:
        return None
    words: list[int] = []
    for value in values:
        if type(value) not in (int, float):
            return None
        try:
            number = float(value)
        except OverflowError:
            return None
        if not math.isfinite(number) or number != math.trunc(number):
            return None
        words.append(int(number))
    degree = words[0]
    if not 2 <= degree <= 6 or len(values) != degree + 6:
        return None
    coefficients = [float(value) for value in words[1:degree + 2]]
    if any(value < -16 or value > 16 for value in words[1:degree + 2]) or coefficients[-1] == 0:
        return None
    re_milli, im_milli, tolerance_micro, iterations = words[degree + 2:degree + 6]
    if (not -4000 <= re_milli <= 4000 or not -4000 <= im_milli <= 4000
            or not 1 <= tolerance_micro <= 1000 or not 8 <= iterations <= 128):
        return None
    return degree, coefficients, complex(re_milli / 1000.0, im_milli / 1000.0), tolerance_micro / 1e6, iterations


def _evaluate(coefficients: list[float], z: complex) -> complex:
    value = complex(coefficients[-1], 0.0)
    for coefficient in reversed(coefficients[:-1]):
        value = value * z + coefficient
    return value


def _root_set(coefficients: list[float]) -> list[tuple[Decimal, Decimal]] | None:
    degree = len(coefficients) - 1
    with localcontext() as context:
        context.prec = 70
        decimal_coefficients = [Decimal(str(value)) for value in coefficients]
        lead = abs(decimal_coefficients[-1])
        radius = Decimal(1) + max(abs(value) / lead for value in decimal_coefficients[:-1])
        roots = []
        for index in range(degree):
            angle = 2.0 * math.pi * (index + 0.271828) / degree
            roots.append((radius * Decimal(str(math.cos(angle))),
                          radius * Decimal(str(math.sin(angle)))))

        def add(a: tuple[Decimal, Decimal], b: tuple[Decimal, Decimal]) -> tuple[Decimal, Decimal]:
            return a[0] + b[0], a[1] + b[1]

        def sub(a: tuple[Decimal, Decimal], b: tuple[Decimal, Decimal]) -> tuple[Decimal, Decimal]:
            return a[0] - b[0], a[1] - b[1]

        def mul(a: tuple[Decimal, Decimal], b: tuple[Decimal, Decimal]) -> tuple[Decimal, Decimal]:
            return a[0] * b[0] - a[1] * b[1], a[0] * b[1] + a[1] * b[0]

        def div(a: tuple[Decimal, Decimal], b: tuple[Decimal, Decimal]) -> tuple[Decimal, Decimal] | None:
            denominator = b[0] * b[0] + b[1] * b[1]
            if denominator == 0:
                return None
            return ((a[0] * b[0] + a[1] * b[1]) / denominator,
                    (a[1] * b[0] - a[0] * b[1]) / denominator)

        def evaluate(z: tuple[Decimal, Decimal]) -> tuple[Decimal, Decimal]:
            value = (decimal_coefficients[-1], Decimal(0))
            for coefficient in reversed(decimal_coefficients[:-1]):
                value = add(mul(value, z), (coefficient, Decimal(0)))
            return value

        for _ in range(512):
            updated: list[tuple[Decimal, Decimal]] = []
            largest_change = Decimal(0)
            for index, root in enumerate(roots):
                denominator = (Decimal(1), Decimal(0))
                for other_index, other in enumerate(roots):
                    if other_index != index:
                        denominator = mul(denominator, sub(root, other))
                correction = div(evaluate(root), denominator)
                if correction is None:
                    return None
                next_root = sub(root, correction)
                updated.append(next_root)
                difference = sub(next_root, root)
                largest_change = max(largest_change,
                                     (difference[0] * difference[0] + difference[1] * difference[1]).sqrt())
            roots = updated
            if largest_change <= Decimal("1e-55"):
                return roots
    return None


def candidate_is_root(values: Sequence[int | float], candidate: Sequence[float]) -> bool:
    """Validate a finite candidate against both a direct residual and DK roots."""
    parsed = _decode(values)
    if parsed is None or not isinstance(candidate, (list, tuple)) or len(candidate) != 2:
        return False
    if any(type(item) not in (int, float) for item in candidate):
        return False
    try:
        candidate_values = (float(candidate[0]), float(candidate[1]))
    except OverflowError:
        return False
    if not all(math.isfinite(item) for item in candidate_values):
        return False
    degree, coefficients, _, tolerance, _ = parsed
    z = complex(*candidate_values)
    residual = abs(_evaluate(coefficients, z))
    scale = sum(abs(coefficient) * abs(z) ** power
                for power, coefficient in enumerate(coefficients))
    if residual > tolerance * max(1.0, scale):
        return False
    roots = _root_set(coefficients)
    if roots is None:
        return False
    with localcontext() as context:
        context.prec = 70
        candidate_decimal = (Decimal(str(candidate_values[0])), Decimal(str(candidate_values[1])))
        closeness = Decimal(str(max(1e-7, tolerance * 2.0)))
        for root in roots[:degree]:
            dx = candidate_decimal[0] - root[0]
            dy = candidate_decimal[1] - root[1]
            distance = (dx * dx + dy * dy).sqrt()
            root_magnitude = (root[0] * root[0] + root[1] * root[1]).sqrt()
            if distance <= closeness * max(Decimal(1), root_magnitude):
                return True
    return False


def zero_correction_is_singular(values: Sequence[int | float]) -> bool:
    """Recognize the explicit stationary seed fixture without Laguerre updates."""
    parsed = _decode(values)
    if parsed is None:
        return False
    degree, coefficients, z, _, _ = parsed
    derivative = [index * coefficients[index] for index in range(1, degree + 1)]
    second = [index * derivative[index] for index in range(1, degree)]
    return (_evaluate(coefficients, z) != 0j
            and _evaluate(derivative, z) == 0j
            and _evaluate(second, z) == 0j)
