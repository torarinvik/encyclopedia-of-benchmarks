"""Stable double-precision oracle for bounded one-dimensional softmax."""

from __future__ import annotations

import math

MIN_LENGTH = 1
MAX_LENGTH = 64
MIN_LOGIT = -20.0
MAX_LOGIT = 20.0


def expected_result(values: list[float] | tuple[float, ...]) -> list[float] | None:
    if (not isinstance(values, (list, tuple)) or not MIN_LENGTH <= len(values) <= MAX_LENGTH
            or any(type(value) not in (int, float) or not math.isfinite(float(value))
                   for value in values)):
        return None
    logits = [float(value) for value in values]
    if any(value < MIN_LOGIT or value > MAX_LOGIT for value in logits):
        return None

    largest = max(logits)
    exponentials = [math.exp(value - largest) for value in logits]
    total = math.fsum(exponentials)
    return [value / total for value in exponentials]
