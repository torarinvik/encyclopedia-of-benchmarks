"""Independent oracle for the bounded R Pearson correlation-matrix ABI."""

from __future__ import annotations

import math
import struct

INVALID_RESULT = -1
CAPACITY_RESULT = -2
OBSERVATIONS = 4
MIN_VARIABLES = 2
MAX_VARIABLES = 5
MIN_VALUE = -1000
MAX_VALUE = 1000
MAX_OUTPUT_BYTES = 4 * MAX_VARIABLES * MAX_VARIABLES * 8 + 6 * 8
I64_MIN, I64_MAX = -(1 << 63), (1 << 63) - 1


def expected_output(values: tuple[int, ...] | list[int],
                    output_capacity: int | None = None) -> tuple[int, bytes]:
    """Return four row-major binary64 matrices and six signed-i64 summary fields."""
    if (not isinstance(values, (tuple, list)) or not 2 <= len(values) <= 2 + OBSERVATIONS * MAX_VARIABLES
            or any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values)):
        return INVALID_RESULT, b""
    n, p = values[:2]
    if n != OBSERVATIONS or not MIN_VARIABLES <= p <= MAX_VARIABLES or len(values) != 2 + n * p:
        return INVALID_RESULT, b""
    if output_capacity is not None and (type(output_capacity) is not int or output_capacity < 0):
        return INVALID_RESULT, b""

    columns = [[values[2 + row * p + col] for row in range(n)] for col in range(p)]
    if any(any(not MIN_VALUE <= value <= MAX_VALUE for value in column) for column in columns):
        return INVALID_RESULT, b""
    if any(all(value == column[0] for value in column[1:]) for column in columns):
        return INVALID_RESULT, b""

    means = [sum(column) / n for column in columns]
    centered = [[float(value) - means[col] for value in column]
                for col, column in enumerate(columns)]
    correlations = [0.0] * (p * p)
    raw_p = [1.0] * (p * p)
    bonferroni = [1.0] * (p * p)
    fdr = [1.0] * (p * p)
    for i in range(p):
        correlations[i * p + i] = 1.0

    pair_indices: list[tuple[int, int]] = []
    pair_p: list[float] = []
    for j in range(1, p):
        for i in range(j):
            cross = sum(centered[i][row] * centered[j][row] for row in range(n))
            sum_i = sum(centered[i][row] * centered[i][row] for row in range(n))
            sum_j = sum(centered[j][row] * centered[j][row] for row in range(n))
            r = cross / math.sqrt(sum_i * sum_j)
            p_value = 1.0 - abs(r)  # Pearson cor.test, df=2 for exactly four observations.
            correlations[i * p + j] = correlations[j * p + i] = r
            raw_p[i * p + j] = raw_p[j * p + i] = p_value
            pair_indices.append((i, j))
            pair_p.append(p_value)

    tests = len(pair_p)
    for index, (i, j) in enumerate(pair_indices):
        adjusted = min(1.0, pair_p[index] * tests)
        bonferroni[i * p + j] = bonferroni[j * p + i] = adjusted

    ordered = sorted(range(tests), key=lambda index: pair_p[index])
    running_min = 1.0
    adjusted_sorted = [1.0] * tests
    for position in range(tests - 1, -1, -1):
        scaled = pair_p[ordered[position]] * tests / (position + 1)
        running_min = min(running_min, scaled, 1.0)
        adjusted_sorted[position] = running_min
    for position, pair_index in enumerate(ordered):
        i, j = pair_indices[pair_index]
        fdr[i * p + j] = fdr[j * p + i] = adjusted_sorted[position]

    significant_uncorrected = sum(pair_p[index] < 0.05 for index in range(tests))
    significant_bonferroni = sum(bonferroni[i * p + j] < 0.05 for i, j in pair_indices)
    significant_fdr = sum(fdr[i * p + j] < 0.05 for i, j in pair_indices)
    summary = [OBSERVATIONS, p, 0, significant_uncorrected,
               significant_bonferroni, significant_fdr]
    output = b"".join(struct.pack("<d", value)
                      for matrix in (correlations, raw_p, bonferroni, fdr)
                      for value in matrix)
    output += b"".join(struct.pack("<q", value) for value in summary)
    if output_capacity is not None and output_capacity < len(output):
        return CAPACITY_RESULT, b""
    return len(output), output
