"""Independent exact-integral verifier for bounded Gauss-Kronrod quadrature."""

from __future__ import annotations

import heapq
import math
from collections.abc import Sequence

from adaptive_gauss_kronrod_15_quadrature_oracle import (
    MAX_INTERVALS,
    MAX_OUTPUT_ELEMENTS,
    MAX_PARSEABLE_INPUT_LENGTH,
    MAX_VALID_INPUT_LENGTH,
    MAX_ENDPOINT_MICRO,
    MIN_ENDPOINT_MICRO,
    MIN_TOLERANCE_EXPONENT,
    MAX_TOLERANCE_EXPONENT,
    OUTPUT_ERROR,
    INVALID_RESULT,
    NUMERICAL_FAILURE,
    SCALE,
)

_NODES = (
    0.991455371120812639206854697526329,
    0.949107912342758524526189684047851,
    0.864864423359769072789712788640926,
    0.741531185599394439863864773280788,
    0.586087235467691130294144838258730,
    0.405845151377397166906606412076961,
    0.207784955007898467600689403773245,
)
_KRONROD_WEIGHTS = (
    0.022935322010529224963732008058970,
    0.063092092629978553290700663189204,
    0.104790010322250183839876322541518,
    0.140653259715525918745189590510238,
    0.169004726639267902826583426598550,
    0.190350578064785409913256402421014,
    0.204432940075298892414161999234649,
)
_KRONROD_CENTER = 0.209482141084727828012999174891714
_GAUSS_WEIGHTS = (
    0.129484966168869693270611432679082,
    0.279705391489276667901467771423780,
    0.381830050505118944950369775488975,
)
_GAUSS_CENTER = 0.417959183673469387755102040816327


def _sample(function_id: int, x: float) -> float:
    if function_id == 0:
        return math.exp(4.0 * x)
    if function_id == 1:
        return math.sin(10.0 * x)
    if function_id == 2:
        return 1.0 / (1.0 + 9.0 * x * x)
    return x ** 14


def _independent_pair(function_id: int, a: float, b: float) -> tuple[float, float]:
    midpoint = a + (b - a) * 0.5
    radius = (b - a) * 0.5
    midpoint_sample = _sample(function_id, midpoint)
    kronrod = _KRONROD_CENTER * midpoint_sample
    gauss = _GAUSS_CENTER * midpoint_sample
    gauss_slot = 0
    for slot in range(7):
        displacement = radius * _NODES[slot]
        samples = (_sample(function_id, midpoint - displacement)
                   + _sample(function_id, midpoint + displacement))
        kronrod += _KRONROD_WEIGHTS[slot] * samples
        if slot % 2 == 1:
            gauss += _GAUSS_WEIGHTS[gauss_slot] * samples
            gauss_slot += 1
    return radius * kronrod, radius * gauss


def _parse(values: Sequence[int | float], input_is_null: bool,
           input_length: int) -> tuple[int, float, float, int, int] | None:
    if (not isinstance(values, (tuple, list)) or input_is_null
            or type(input_length) is not int
            or not 0 <= input_length <= MAX_PARSEABLE_INPUT_LENGTH
            or len(values) > MAX_PARSEABLE_INPUT_LENGTH
            or input_length != len(values) or input_length != MAX_VALID_INPUT_LENGTH):
        return None
    if any(type(value) not in (int, float) or not math.isfinite(float(value))
           or not float(value).is_integer() for value in values):
        return None
    fields = [int(float(value)) for value in values]
    function_id, a_micro, b_micro, exponent, interval_limit = fields
    if (not 0 <= function_id <= 3
            or not MIN_ENDPOINT_MICRO <= a_micro <= MAX_ENDPOINT_MICRO
            or not MIN_ENDPOINT_MICRO <= b_micro <= MAX_ENDPOINT_MICRO
            or a_micro > b_micro
            or not MIN_TOLERANCE_EXPONENT <= exponent <= MAX_TOLERANCE_EXPONENT
            or not 1 <= interval_limit <= MAX_INTERVALS):
        return None
    return function_id, a_micro / SCALE, b_micro / SCALE, exponent, interval_limit


def _converges_by_priority_queue(
        parsed: tuple[int, float, float, int, int]) -> bool:
    """Check the stopping status with a max-priority queue and active map."""
    function_id, a, b, exponent, limit = parsed
    if a == b:
        return True
    tolerance = 10.0 ** (-exponent)
    next_id = 0
    k_value, g_value = _independent_pair(function_id, a, b)
    active: dict[int, tuple[float, float, float, float]] = {
        next_id: (a, b, k_value, abs(k_value - g_value))
    }
    heap: list[tuple[float, float, int]] = [(-abs(k_value - g_value), a, next_id)]
    while True:
        total = sum(item[2] for item in active.values())
        error = sum(item[3] for item in active.values())
        if error <= tolerance * max(1.0, abs(total)):
            return True
        if len(active) >= limit:
            return False
        _, _, parent_id = heapq.heappop(heap)
        left, right, _, _ = active.pop(parent_id)
        middle = (left + right) * 0.5
        for child_a, child_b in ((left, middle), (middle, right)):
            child_k, child_g = _independent_pair(function_id, child_a, child_b)
            error_value = abs(child_k - child_g)
            next_id += 1
            active[next_id] = (child_a, child_b, child_k, error_value)
            heapq.heappush(heap, (-error_value, child_a, next_id))


def _exact_integral(function_id: int, a: float, b: float) -> float:
    if function_id == 0:
        return (math.exp(4.0 * b) - math.exp(4.0 * a)) / 4.0
    if function_id == 1:
        return (math.cos(10.0 * a) - math.cos(10.0 * b)) / 10.0
    if function_id == 2:
        return (math.atan(3.0 * b) - math.atan(3.0 * a)) / 3.0
    return (b ** 15 - a ** 15) / 15.0


def expected_output(
        values: Sequence[int | float], capacity: int = MAX_OUTPUT_ELEMENTS,
        output_is_null: bool = False, input_is_null: bool = False,
        input_length: int | None = None,
) -> tuple[int, tuple[float, ...]]:
    """Return exact mathematical output after independently checking status."""
    effective_length = (len(values) if input_length is None
                        and isinstance(values, (tuple, list)) else input_length)
    if effective_length is None:
        return INVALID_RESULT, ()
    parsed = _parse(values, input_is_null, effective_length)
    if parsed is None:
        return INVALID_RESULT, ()
    if type(capacity) is not int or capacity < 0 or type(output_is_null) is not bool:
        return INVALID_RESULT, ()
    if output_is_null or capacity < 1:
        return OUTPUT_ERROR, ()
    function_id, a, b, exponent, limit = parsed
    if not _converges_by_priority_queue((function_id, a, b, exponent, limit)):
        return NUMERICAL_FAILURE, ()
    answer = _exact_integral(function_id, a, b)
    if not math.isfinite(answer):
        return INVALID_RESULT, ()
    return 1, (answer,)
