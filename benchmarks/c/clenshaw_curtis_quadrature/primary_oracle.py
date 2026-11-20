"""Primary DLMF-weight binary64 oracle for the bounded profile."""

from __future__ import annotations

import math
from collections.abc import Sequence

INVALID_RESULT = -1
OUTPUT_ERROR = -2
MIN_N = 2
MAX_N = 16
MAX_VALID_INPUT_LENGTH = 18
MAX_PARSEABLE_INPUT_LENGTH = 19
MAX_OUTPUT_ELEMENTS = 1
WORKSPACE_ELEMENTS = 1
WORKSPACE_BYTES = 8
ABSOLUTE_TOLERANCE = 1e-9
RELATIVE_TOLERANCE = 1e-12


def _finite(value: object) -> bool:
    if type(value) not in (int, float):
        return False
    try:
        return math.isfinite(float(value))
    except OverflowError:
        return False


def _decode(values: Sequence[int | float], input_is_null: bool,
            input_length: int) -> tuple[int, tuple[float, ...]] | None:
    if (not isinstance(values, (list, tuple)) or type(input_is_null) is not bool
            or type(input_length) is not int or input_is_null
            or not 0 <= input_length <= MAX_PARSEABLE_INPUT_LENGTH
            or len(values) > MAX_PARSEABLE_INPUT_LENGTH or input_length != len(values)
            or input_length < MIN_N + 2):
        return None
    if any(not _finite(value) for value in values):
        return None
    raw_n = float(values[0])
    if not raw_n.is_integer():
        return None
    n = int(raw_n)
    if n < MIN_N or n > MAX_N or n % 2 != 0 or input_length != n + 2:
        return None
    samples = tuple(float(value) for value in values[1:])
    if len(samples) != n + 1 or any(abs(sample) > 1000.0 for sample in samples):
        return None
    return n, samples


def _clenshaw_curtis(n: int, samples: tuple[float, ...]) -> float:
    result = 0.0
    for k in range(n + 1):
        inner = 0.0
        for j in range(1, n // 2 + 1):
            bj = 1.0 if j == n // 2 else 2.0
            denominator = float(4 * j * j - 1)
            angle = (((2.0 * float(j)) * float(k)) * math.pi) / float(n)
            term = (bj / denominator) * math.cos(angle)
            inner += term
        gk = 1.0 if k == 0 or k == n else 2.0
        weight = (gk / float(n)) * (1.0 - inner)
        result += weight * samples[k]
    return result


def expected_output(values: Sequence[int | float], capacity: int | None = 1,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, tuple[float, ...]]:
    effective_length = (len(values) if input_length is None
                        and isinstance(values, (tuple, list)) else input_length)
    if effective_length is None:
        return INVALID_RESULT, ()
    decoded = _decode(values, input_is_null, effective_length)
    if decoded is None:
        return INVALID_RESULT, ()
    if type(output_is_null) is not bool or (capacity is not None and
            (type(capacity) is not int or capacity < 0)):
        return INVALID_RESULT, ()
    if output_is_null or (capacity is not None and capacity < MAX_OUTPUT_ELEMENTS):
        return OUTPUT_ERROR, ()
    result = _clenshaw_curtis(*decoded)
    return (1, (result,)) if math.isfinite(result) else (INVALID_RESULT, ())
