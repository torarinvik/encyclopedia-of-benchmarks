"""Independent oracle for the bounded streaming trailing-window median filter."""

from __future__ import annotations

import math


MIN_WINDOW_SIZE = 1
MAX_WINDOW_SIZE = 16
MIN_SAMPLE_COUNT = 0
MAX_SAMPLE_COUNT = 64
MAX_INPUT_LENGTH = 2 + MAX_SAMPLE_COUNT
MAX_OUTPUT_ELEMENTS = MAX_SAMPLE_COUNT
MIN_SAMPLE = -1_000_000.0
MAX_SAMPLE = 1_000_000.0
INVALID_RESULT = -1
OUTPUT_ERROR = -2


def _exact_int(value: object) -> int | None:
    if type(value) not in (int, float):
        return None
    try:
        number = float(value)
    except (OverflowError, ValueError):
        return None
    if not math.isfinite(number) or number != math.floor(number):
        return None
    return int(number)


def expected_result(values: list[float] | tuple[float, ...]) -> list[float] | None:
    """Return one causal median per sample, or ``None`` for an invalid input."""
    if not isinstance(values, (list, tuple)) or len(values) < 2:
        return None

    window_size = _exact_int(values[0])
    sample_count = _exact_int(values[1])
    if (window_size is None or not MIN_WINDOW_SIZE <= window_size <= MAX_WINDOW_SIZE
            or sample_count is None
            or not MIN_SAMPLE_COUNT <= sample_count <= MAX_SAMPLE_COUNT
            or len(values) != 2 + sample_count):
        return None

    samples: list[float] = []
    for value in values[2:]:
        if type(value) not in (int, float):
            return None
        try:
            sample = float(value)
        except (OverflowError, ValueError):
            return None
        if not math.isfinite(sample) or not MIN_SAMPLE <= sample <= MAX_SAMPLE:
            return None
        samples.append(sample)

    result: list[float] = []
    for end_index in range(len(samples)):
        start_index = max(0, end_index - window_size + 1)
        window = sorted(samples[start_index:end_index + 1])
        middle = len(window) // 2
        if len(window) % 2:
            result.append(window[middle])
        else:
            result.append(0.5 * (window[middle - 1] + window[middle]))
    return result
