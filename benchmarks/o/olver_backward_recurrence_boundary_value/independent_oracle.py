"""Independent boundary-system solve for the selected Olver cutoff."""

from __future__ import annotations

import math
from collections.abc import Sequence

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


def _decode_independently(values: Sequence[int | float] | None,
                          is_null: bool,
                          length: int | None) -> tuple[int, int, float, float,
                                                        list[float], list[float],
                                                        list[float], list[float]] | None:
    if type(is_null) is not bool or is_null or not isinstance(values, (list, tuple)):
        return None
    if any(type(v) not in (int, float) or not math.isfinite(float(v)) for v in values):
        return None
    actual = len(values) if length is None else length
    if type(actual) is not int or actual != len(values) or actual < 8 or actual > 53:
        return None
    m_value, cap_value = float(values[0]), float(values[1])
    if (not m_value.is_integer() or not cap_value.is_integer()
            or not 1 <= m_value <= 8 or not 1 <= cap_value <= 12):
        return None
    m, cap = int(m_value), int(cap_value)
    if m > cap or actual != 4 + 4 * cap:
        return None
    tolerance, initial = float(values[2]), float(values[3])
    if not 2.0 ** -40 <= tolerance <= 0.5 or abs(initial) > 16.0:
        return None
    arrays = [list(map(float, values[4 + j * cap:4 + (j + 1) * cap])) for j in range(4)]
    if any(not 1.0 / 16.0 <= abs(v) <= 16.0 for v in arrays[0]):
        return None
    if any(abs(v) > 16.0 for arr in arrays[1:] for v in arr):
        return None
    return m, cap, tolerance, initial, arrays[0], arrays[1], arrays[2], arrays[3]


def _choose_endpoint(m: int, cap: int, eps: float, w0: float,
                     a: Sequence[float], b: Sequence[float],
                     c: Sequence[float], d: Sequence[float]) -> int | None:
    p = [0.0] * (cap + 2)
    e = [0.0] * (cap + 1)
    p[1] = 1.0
    e[0] = w0
    for n in range(1, m + 1):
        p[n + 1] = (b[n - 1] * p[n] - c[n - 1] * p[n - 1]) / a[n - 1]
        e[n] = (c[n - 1] * e[n - 1] - d[n - 1] * p[n]) / a[n - 1]
        if not math.isfinite(p[n + 1]) or not math.isfinite(e[n]):
            return None
    score: list[float] = [0.0] * (cap + 1)
    for n in range(1, m + 1):
        scale = p[n] * p[n + 1]
        if scale == 0.0 or not math.isfinite(scale):
            return None
        score[n] = abs(e[n] / scale)
        if not math.isfinite(score[n]):
            return None
    limit = eps * min(score[1:m + 1])
    for endpoint in range(m, cap + 1):
        if endpoint > m:
            p[endpoint + 1] = (b[endpoint - 1] * p[endpoint] - c[endpoint - 1] * p[endpoint - 1]) / a[endpoint - 1]
            e[endpoint] = (c[endpoint - 1] * e[endpoint - 1] - d[endpoint - 1] * p[endpoint]) / a[endpoint - 1]
            if not math.isfinite(p[endpoint + 1]) or not math.isfinite(e[endpoint]):
                return None
        scale = p[endpoint] * p[endpoint + 1]
        if scale == 0.0 or not math.isfinite(scale):
            return None
        score[endpoint] = abs(e[endpoint] / scale)
        if not math.isfinite(score[endpoint]):
            return None
        if score[endpoint] <= limit:
            return endpoint
    return None


def _boundary_values(m: int, endpoint: int, w0: float,
                     a: Sequence[float], b: Sequence[float],
                     c: Sequence[float], d: Sequence[float]) -> list[float] | None:
    interior = endpoint - 1
    matrix = [[0.0] * (interior + 1) for _ in range(interior)]
    for row in range(interior):
        n = row + 1
        matrix[row][row] = -b[n - 1]
        if n == 1:
            matrix[row][interior] = d[n - 1] - c[n - 1] * w0
        else:
            matrix[row][n - 2] = c[n - 1]
            matrix[row][interior] = d[n - 1]
        if n + 1 < endpoint:
            matrix[row][n] = a[n - 1]
    for col in range(interior):
        pivot = max(range(col, interior), key=lambda row: abs(matrix[row][col]))
        if matrix[pivot][col] == 0.0:
            return None
        matrix[col], matrix[pivot] = matrix[pivot], matrix[col]
        scale = matrix[col][col]
        for j in range(col, interior + 1):
            matrix[col][j] /= scale
        for row in range(interior):
            if row == col:
                continue
            factor = matrix[row][col]
            for j in range(col, interior + 1):
                matrix[row][j] -= factor * matrix[col][j]
    values = [0.0] * (endpoint + 1)
    values[0] = w0
    values[endpoint] = 0.0
    for index in range(1, endpoint):
        values[index] = matrix[index - 1][interior]
        if not math.isfinite(values[index]):
            return None
    return [float(endpoint), *values[:m + 1]]


def expected_output(values: Sequence[int | float] | None,
                    capacity: int | None = MAX_OUTPUT_ELEMENTS,
                    output_is_null: bool = False,
                    input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, tuple[float, ...]]:
    decoded = _decode_independently(values, input_is_null, input_length)
    if decoded is None:
        return INVALID_RESULT, ()
    m, cap, eps, w0, a, b, c, d = decoded
    required = m + 2
    if (type(output_is_null) is not bool or (capacity is not None and
            (type(capacity) is not int or capacity < 0))):
        return INVALID_RESULT, ()
    if output_is_null or (capacity is not None and capacity < required):
        return OUTPUT_ERROR, ()
    endpoint = _choose_endpoint(m, cap, eps, w0, a, b, c, d)
    if endpoint is None:
        return RECURRENCE_ERROR, ()
    result = _boundary_values(m, endpoint, w0, a, b, c, d)
    if result is None:
        return RECURRENCE_ERROR, ()
    return required, tuple(result)
