"""Primary bounded adaptive Gauss-Kronrod 7/15 ABI oracle."""

from __future__ import annotations

import math
from collections.abc import Sequence

INVALID_RESULT = -1
OUTPUT_ERROR = -2
NUMERICAL_FAILURE = -3
MAX_VALID_INPUT_LENGTH = 5
MAX_PARSEABLE_INPUT_LENGTH = 6
MAX_OUTPUT_ELEMENTS = 1
MAX_INTERVALS = 16
SCALE = 1_000_000
MIN_ENDPOINT_MICRO = -1_000_000
MAX_ENDPOINT_MICRO = 1_000_000
MIN_TOLERANCE_EXPONENT = 6
MAX_TOLERANCE_EXPONENT = 8
ABSOLUTE_TOLERANCE = 2e-7
RELATIVE_TOLERANCE = 2e-7

_XGK = (
    0.991455371120812639206854697526329,
    0.949107912342758524526189684047851,
    0.864864423359769072789712788640926,
    0.741531185599394439863864773280788,
    0.586087235467691130294144838258730,
    0.405845151377397166906606412076961,
    0.207784955007898467600689403773245,
)
_WGK = (
    0.022935322010529224963732008058970,
    0.063092092629978553290700663189204,
    0.104790010322250183839876322541518,
    0.140653259715525918745189590510238,
    0.169004726639267902826583426598550,
    0.190350578064785409913256402421014,
    0.204432940075298892414161999234649,
)
_WGK_CENTER = 0.209482141084727828012999174891714
_WG = (0.129484966168869693270611432679082,
       0.279705391489276667901467771423780,
       0.381830050505118944950369775488975)
_WG_CENTER = 0.417959183673469387755102040816327


def _finite(value: object) -> bool:
    return type(value) in (int, float) and math.isfinite(float(value))


def _parse(values: Sequence[int | float], input_is_null: bool,
           input_length: int) -> tuple[int, float, float, float, int] | None:
    if (not isinstance(values, (tuple, list))
            or type(input_is_null) is not bool
            or type(input_length) is not int
            or not 0 <= input_length <= MAX_PARSEABLE_INPUT_LENGTH
            or len(values) > MAX_PARSEABLE_INPUT_LENGTH
            or any(not _finite(value) for value in values)
            or input_is_null
            or input_length != len(values)
            or input_length != MAX_VALID_INPUT_LENGTH):
        return None
    fields: list[int] = []
    for value in values:
        numeric = float(value)
        if not numeric.is_integer():
            return None
        fields.append(int(numeric))
    function_id, a_micro, b_micro, exponent, interval_limit = fields
    if (not 0 <= function_id <= 3
            or not MIN_ENDPOINT_MICRO <= a_micro <= MAX_ENDPOINT_MICRO
            or not MIN_ENDPOINT_MICRO <= b_micro <= MAX_ENDPOINT_MICRO
            or a_micro > b_micro
            or not MIN_TOLERANCE_EXPONENT <= exponent <= MAX_TOLERANCE_EXPONENT
            or not 1 <= interval_limit <= MAX_INTERVALS):
        return None
    return (function_id, a_micro / SCALE, b_micro / SCALE,
            10.0 ** (-exponent), interval_limit)


def _sample(function_id: int, x: float) -> float:
    if function_id == 0:
        return math.exp(4.0 * x)
    if function_id == 1:
        return math.sin(10.0 * x)
    if function_id == 2:
        return 1.0 / (1.0 + 9.0 * x * x)
    return x ** 14


def _pair(function_id: int, a: float, b: float) -> tuple[float, float]:
    """Return the Kronrod-15 estimate and its embedded Gauss-7 estimate."""
    center = (a + b) * 0.5
    half = (b - a) * 0.5
    center_value = _sample(function_id, center)
    kronrod_sum = _WGK_CENTER * center_value
    gauss_sum = _WG_CENTER * center_value
    for index, node in enumerate(_XGK):
        offset = half * node
        pair_sum = _sample(function_id, center - offset) + _sample(function_id, center + offset)
        kronrod_sum += _WGK[index] * pair_sum
        if index in (1, 3, 5):
            gauss_sum += _WG[(index - 1) // 2] * pair_sum
    return half * kronrod_sum, half * gauss_sum


def _adaptive_estimate(parsed: tuple[int, float, float, float, int]) -> float | None:
    function_id, a, b, tolerance, interval_limit = parsed
    if a == b:
        return 0.0
    first_k, first_g = _pair(function_id, a, b)
    intervals: list[tuple[float, float, float, float]] = [(a, b, first_k, abs(first_k - first_g))]
    while True:
        total = sum(interval[2] for interval in intervals)
        error = sum(interval[3] for interval in intervals)
        if error <= tolerance * max(1.0, abs(total)):
            return total
        if len(intervals) >= interval_limit:
            return None
        split_index = 0
        for index in range(1, len(intervals)):
            if (intervals[index][3] > intervals[split_index][3]
                    or (intervals[index][3] == intervals[split_index][3]
                        and intervals[index][0] < intervals[split_index][0])):
                split_index = index
        left, right, _, _ = intervals[split_index]
        middle = (left + right) * 0.5
        left_k, left_g = _pair(function_id, left, middle)
        right_k, right_g = _pair(function_id, middle, right)
        intervals[split_index] = (left, middle, left_k, abs(left_k - left_g))
        intervals.append((middle, right, right_k, abs(right_k - right_g)))


def expected_output(
        values: Sequence[int | float], capacity: int = MAX_OUTPUT_ELEMENTS,
        output_is_null: bool = False, input_is_null: bool = False,
        input_length: int | None = None,
) -> tuple[int, tuple[float, ...]]:
    """Return status and staged output, with input errors taking precedence."""
    effective_length = (len(values) if input_length is None
                        and isinstance(values, (tuple, list)) else input_length)
    if effective_length is None:
        return INVALID_RESULT, ()
    parsed = _parse(values, input_is_null, effective_length)
    if parsed is None:
        return INVALID_RESULT, ()
    if (type(capacity) is not int or capacity < 0
            or type(output_is_null) is not bool):
        return INVALID_RESULT, ()
    if output_is_null or capacity < 1:
        return OUTPUT_ERROR, ()
    result = _adaptive_estimate(parsed)
    if result is None:
        return NUMERICAL_FAILURE, ()
    if not math.isfinite(result):
        return INVALID_RESULT, ()
    return 1, (result,)
