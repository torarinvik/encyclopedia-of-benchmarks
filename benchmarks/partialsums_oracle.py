"""Independent bounded oracle for the BenchmarkGame partialsums workload."""

from __future__ import annotations

import math

MIN_N = 1
MAX_N = 10_000
OUTPUT_COUNT = 9


def expected_output(values: list[float]) -> list[float] | None:
    if len(values) != 1:
        return None
    value = values[0]
    if not math.isfinite(value) or value != math.trunc(value) or not MIN_N <= value <= MAX_N:
        return None

    n = int(value)
    geometric = 0.0
    inverse_sqrt = 0.0
    flint_hills = 0.0
    cookson_hills = 0.0
    lanes = [[0.0, 0.0] for _ in range(5)]
    term = 1.0
    # The source vector loop tests only its odd-number lane. For odd n, its
    # final two-lane iteration therefore includes the following even k=n+1.
    vector_limit = n + (n & 1)
    for k in range(1, vector_limit + 1):
        if k <= n:
            geometric += term
            term *= 2.0 / 3.0
            inverse_sqrt += 1.0 / math.sqrt(k)
            k3 = float(k) * float(k) * float(k)
            sine = math.sin(float(k))
            cosine = math.cos(float(k))
            flint_hills += 1.0 / (k3 * sine * sine)
            cookson_hills += 1.0 / (k3 * cosine * cosine)

        lane = (k - 1) & 1
        kf = float(k)
        lanes[0][lane] += 1.0 / (kf * (kf + 1.0))
        lanes[1][lane] += 1.0 / kf
        lanes[2][lane] += 1.0 / (kf * kf)
        lanes[3][lane] += (1.0 if lane == 0 else -1.0) / kf
        lanes[4][lane] += (1.0 if lane == 0 else -1.0) / (2.0 * kf - 1.0)

    return [
        geometric,
        inverse_sqrt,
        lanes[0][0] + lanes[0][1],
        flint_hills,
        cookson_hills,
        lanes[1][0] + lanes[1][1],
        lanes[2][0] + lanes[2][1],
        lanes[3][0] + lanes[3][1],
        lanes[4][0] + lanes[4][1],
    ]
