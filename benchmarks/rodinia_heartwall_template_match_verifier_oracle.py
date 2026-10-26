"""Independent real-valued verifier for bounded Heartwall candidate selection."""

import math
from collections.abc import Sequence

INVALID_RESULT = -1
MAX_INPUT_LENGTH = 85
MAX_OUTPUT_BYTES = 8


def select_candidate(values: Sequence[int]) -> int:
    if not isinstance(values, (list, tuple)) or len(values) < 5 or len(values) > MAX_INPUT_LENGTH:
        return INVALID_RESULT
    if any(type(v) is not int for v in values):
        return INVALID_RESULT
    ir, ic, tr, tc, mask = values[:5]
    if not (2 <= ir <= 8 and 2 <= ic <= 8 and 2 <= tr <= 4 and 2 <= tc <= 4
            and tr <= ir and tc <= ic and mask >= 0):
        return INVALID_RESULT
    rows, cols = ir - tr + 1, ic - tc + 1
    candidate_count = rows * cols
    if mask >> candidate_count or len(values) != 5 + tr * tc + ir * ic:
        return INVALID_RESULT
    template = values[5:5 + tr * tc]
    image = values[5 + tr * tc:]
    if any(not 0 <= x <= 255 for x in template + image):
        return INVALID_RESULT
    count = tr * tc
    t_sum = sum(template)
    t_mean = t_sum / count
    t_var = sum(x * x for x in template) / count - t_mean * t_mean
    if t_var <= 0.0:
        return INVALID_RESULT

    chosen = 0
    largest = 0.0
    bit = 0
    for x0 in range(cols):
        for y0 in range(rows):
            if mask & (1 << bit):
                patch = [image[(x0 + x) * ir + y0 + y]
                         for x in range(tc) for y in range(tr)]
                p_sum = sum(patch)
                p_var = sum(x * x for x in patch) - p_sum * p_sum / count
                if p_var <= 0.0:
                    return INVALID_RESULT
                covariance = sum(a * b for a, b in zip(template, patch)) - p_sum * t_sum / count
                score = covariance / (math.sqrt(p_var) * math.sqrt(count - 1) * math.sqrt(t_var))
                magnitude = abs(score)
                if not math.isfinite(magnitude):
                    return INVALID_RESULT
                if magnitude > largest:
                    chosen, largest = bit, magnitude
            bit += 1
    return chosen


def expected_bytes(values: Sequence[int]) -> tuple[int, bytes]:
    result = select_candidate(values)
    if result < 0:
        return result, b""
    return 8, result.to_bytes(8, "little", signed=True)
