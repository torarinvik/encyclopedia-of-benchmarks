"""Oracle for Weddle's rule over bounded, fixed-point sample tables."""

from __future__ import annotations

import math

INVALID_RESULT = -1.0e300
MAX_PANELS = 64
MAX_STEP_NANOUNITS = 1_000_000_000
MAX_SAMPLE_MICRO = 1_000_000
MAX_PACKED_VALUES = 387
# Include one extra packed value so the runner can carry an oversized invalid case.
MAX_INPUT_LENGTH = MAX_PACKED_VALUES + 1


def expected_result(values: list[int] | tuple[int, ...]) -> float:
    if (not isinstance(values, (list, tuple)) or len(values) < 2
            or len(values) > MAX_INPUT_LENGTH
            or any(type(value) is not int or not -(2**63) <= value <= 2**63 - 1
                   for value in values)):
        return INVALID_RESULT

    panel_count, step_nanounits = values[:2]
    if (not 1 <= panel_count <= MAX_PANELS
            or len(values) != 6 * panel_count + 3
            or not -MAX_STEP_NANOUNITS <= step_nanounits <= MAX_STEP_NANOUNITS):
        return INVALID_RESULT

    table = values[2:]
    if any(not -MAX_SAMPLE_MICRO <= sample <= MAX_SAMPLE_MICRO for sample in table):
        return INVALID_RESULT

    # The pinned source first builds a list of weighted interior values, then applies
    # Python's left-to-right sum and adds the endpoints before scaling.
    weighted_values: list[float] = []
    for index in range(1, len(table) - 1):
        if index % 2 == 0 and index % 3 != 0:
            weight = 1
        elif index % 2 != 0 and index % 3 != 0:
            weight = 5
        elif index % 6 == 0:
            weight = 2
        else:
            weight = 6
        weighted_values.append(weight * (table[index] / 1_000_000.0))

    step_size = step_nanounits / 1_000_000_000.0
    result = 0.3 * step_size * (
        sum(weighted_values) + table[0] / 1_000_000.0 + table[-1] / 1_000_000.0
    )
    return result if math.isfinite(result) else INVALID_RESULT
