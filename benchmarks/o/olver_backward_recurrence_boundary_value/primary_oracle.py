"""Primary forward p/e and backward Olver recurrence reference."""

from __future__ import annotations

import math
from collections.abc import Sequence

ALGORITHM = "olver_backward_recurrence_boundary_value"
MAX_NMAX = 12
MAX_M = 8
MAX_VALID_INPUT_LENGTH = 52
MAX_PARSEABLE_INPUT_LENGTH = 53
MAX_OUTPUT_ELEMENTS = 10
WORKSPACE_ELEMENTS = 10
WORKSPACE_BYTES = 80
NATIVE_SCRATCH_BYTES = 320
INVALID_RESULT = -1
OUTPUT_ERROR = -2
RECURRENCE_ERROR = -3
ABSOLUTE_TOLERANCE = 1e-9
RELATIVE_TOLERANCE = 1e-12


def _finite_number(value: object) -> bool:
    if type(value) not in (int, float):
        return False
    try:
        return math.isfinite(float(value))
    except OverflowError:
        return False


def _integer(value: int | float, low: int, high: int) -> int | None:
    number = float(value)
    if not math.isfinite(number) or number < low or number > high or not number.is_integer():
        return None
    return int(number)


def _decode(values: Sequence[int | float] | None, input_is_null: bool,
            input_length: int | None) -> tuple[int, int, float, float,
                                                tuple[float, ...], tuple[float, ...],
                                                tuple[float, ...], tuple[float, ...]] | None:
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (tuple, list))
            or any(not _finite_number(value) for value in values)):
        return None
    length = len(values) if input_length is None else input_length
    if (type(length) is not int or length != len(values)
            or length < 8 or length > MAX_PARSEABLE_INPUT_LENGTH):
        return None
    m = _integer(values[0], 1, MAX_M)
    nmax = _integer(values[1], 1, MAX_NMAX)
    if m is None or nmax is None or m > nmax or length != 4 + 4 * nmax:
        return None
    epsilon, w0 = float(values[2]), float(values[3])
    if not (2.0 ** -40 <= epsilon <= 0.5) or abs(w0) > 16.0:
        return None
    blocks = tuple(tuple(float(v) for v in values[4 + block * nmax:4 + (block + 1) * nmax])
                   for block in range(4))
    a, b, c, d = blocks
    if any(not 1.0 / 16.0 <= abs(value) <= 16.0 for value in a):
        return None
    if any(abs(value) > 16.0 for block in (b, c, d) for value in block):
        return None
    return m, nmax, epsilon, w0, a, b, c, d


def _olver(m: int, nmax: int, epsilon: float, w0: float,
           a: Sequence[float], b: Sequence[float],
           c: Sequence[float], d: Sequence[float]) -> list[float] | None:
    p = [0.0] * (nmax + 2)
    e = [0.0] * (nmax + 1)
    p[1] = 1.0
    e[0] = w0
    for n in range(1, m + 1):
        p[n + 1] = (b[n - 1] * p[n] - c[n - 1] * p[n - 1]) / a[n - 1]
        e[n] = (c[n - 1] * e[n - 1] - d[n - 1] * p[n]) / a[n - 1]
        if not math.isfinite(p[n + 1]) or not math.isfinite(e[n]):
            return None
    ratios = [0.0] * (nmax + 1)
    for n in range(1, m + 1):
        denominator = p[n] * p[n + 1]
        if denominator == 0.0 or not math.isfinite(denominator):
            return None
        ratios[n] = abs(e[n] / denominator)
        if not math.isfinite(ratios[n]):
            return None
    minimum = min(ratios[1:m + 1])
    threshold = epsilon * minimum
    endpoint = None
    for n in range(m, nmax + 1):
        if n > m:
            p[n + 1] = (b[n - 1] * p[n] - c[n - 1] * p[n - 1]) / a[n - 1]
            e[n] = (c[n - 1] * e[n - 1] - d[n - 1] * p[n]) / a[n - 1]
            if not math.isfinite(p[n + 1]) or not math.isfinite(e[n]):
                return None
        denominator = p[n] * p[n + 1]
        if denominator == 0.0 or not math.isfinite(denominator):
            return None
        ratios[n] = abs(e[n] / denominator)
        if not math.isfinite(ratios[n]):
            return None
        if ratios[n] <= threshold:
            endpoint = n
            break
    if endpoint is None:
        return None
    w = [0.0] * (endpoint + 1)
    for n in range(endpoint - 1, -1, -1):
        w[n] = (p[n] * w[n + 1] + e[n]) / p[n + 1]
        if not math.isfinite(w[n]):
            return None
    return [float(endpoint), *w[:m + 1]]


def expected_output(values: Sequence[int | float] | None,
                    capacity: int | None = MAX_OUTPUT_ELEMENTS,
                    output_is_null: bool = False,
                    input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, tuple[float, ...]]:
    decoded = _decode(values, input_is_null, input_length)
    if decoded is None:
        return INVALID_RESULT, ()
    m = decoded[0]
    required = m + 2
    if (type(output_is_null) is not bool or (capacity is not None and
            (type(capacity) is not int or capacity < 0))):
        return INVALID_RESULT, ()
    if output_is_null or (capacity is not None and capacity < required):
        return OUTPUT_ERROR, ()
    result = _olver(*decoded)
    if result is None:
        return RECURRENCE_ERROR, ()
    return required, tuple(result)
