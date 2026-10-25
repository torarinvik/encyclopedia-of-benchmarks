"""Independent bounded oracle for Rodinia streamcluster's pgain step."""

from __future__ import annotations

import struct
from typing import Sequence

MAX_POINTS = 8
MAX_DIMENSION = 3
MAX_INPUT_LENGTH = 5 + MAX_POINTS * (3 + MAX_DIMENSION)
MAX_PARSEABLE_INPUT_LENGTH = MAX_INPUT_LENGTH + 1
MAX_OUTPUT_ELEMENTS = 5 + 2 * MAX_POINTS
MAX_OUTPUT_BYTES = MAX_OUTPUT_ELEMENTS * 8


def _invalid(values: Sequence[int] | None) -> bool:
    if values is None or len(values) < 5 or len(values) > MAX_INPUT_LENGTH:
        return True
    if any(not isinstance(x, int) or isinstance(x, bool) for x in values):
        return True
    n, dim, candidate, z, mask = values[:5]
    if not (2 <= n <= MAX_POINTS and 1 <= dim <= MAX_DIMENSION):
        return True
    if len(values) != 5 + n * (3 + dim):
        return True
    if not (0 <= candidate < n and 1 <= z <= 64 and 0 < mask < (1 << n)):
        return True
    if mask & (1 << candidate):
        return True
    cursor = 5
    assignments = list(values[cursor:cursor + n]); cursor += n
    weights = list(values[cursor:cursor + n]); cursor += n
    costs = list(values[cursor:cursor + n]); cursor += n
    coords = [list(values[cursor + i * dim:cursor + (i + 1) * dim]) for i in range(n)]
    if any(a < 0 or a >= n or not (mask & (1 << a)) for a in assignments):
        return True
    if any(not 1 <= w <= 4 for w in weights):
        return True
    if any(not -8 <= x <= 8 for row in coords for x in row):
        return True
    for i in range(n):
        expected = weights[i] * sum((coords[i][k] - coords[assignments[i]][k]) ** 2 for k in range(dim))
        if costs[i] != expected or ((mask & (1 << i)) and (assignments[i] != i or costs[i] != 0)):
            return True
    return False


def expected_output(values: Sequence[int] | None, output_capacity: int | None = None,
                    output_is_null: bool = False) -> tuple[int, bytes]:
    if _invalid(values):
        return -1, b""
    assert values is not None
    n, dim, candidate, z, mask = values[:5]
    cursor = 5
    assignments = list(values[cursor:cursor + n]); cursor += n
    weights = list(values[cursor:cursor + n]); cursor += n
    costs = list(values[cursor:cursor + n]); cursor += n
    coords = [list(values[cursor + i * dim:cursor + (i + 1) * dim]) for i in range(n)]

    def weighted_distance(i: int, j: int) -> int:
        return weights[i] * sum((coords[i][k] - coords[j][k]) ** 2 for k in range(dim))

    switch = [False] * n
    lower = [0] * n
    opening_cost = z
    for i in range(n):
        candidate_cost = weighted_distance(i, candidate)
        if candidate_cost < costs[i]:
            switch[i] = True
            opening_cost += candidate_cost - costs[i]
        else:
            lower[assignments[i]] += costs[i] - candidate_cost
    closing = [False] * n
    for center in range(n):
        if mask & (1 << center):
            low = z + lower[center]
            if low > 0:
                closing[center] = True
                opening_cost -= low

    opened = opening_cost < 0
    gain = -opening_cost if opened else 0
    out_mask = mask
    out_assignments = assignments[:]
    out_costs = costs[:]
    if opened:
        for i in range(n):
            if switch[i] or closing[assignments[i]]:
                out_assignments[i] = candidate
                out_costs[i] = weighted_distance(i, candidate)
        for center in range(n):
            if closing[center]:
                out_mask &= ~(1 << center)
        out_mask |= 1 << candidate
    count = out_mask.bit_count()
    objective = count * z + sum(out_costs)
    result = [int(opened), gain, count, out_mask, objective, *out_assignments, *out_costs]
    payload = b"".join(struct.pack("<q", x) for x in result)
    if output_is_null or (output_capacity is not None and output_capacity < len(payload)):
        return -2, b""
    return len(result), payload
