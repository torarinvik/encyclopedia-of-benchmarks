"""Exact expected-output oracle for the bounded finite-metric k-server profile."""

from __future__ import annotations

import itertools
import struct
from collections.abc import Sequence

MAX_INPUT = 50
MAX_OUTPUT_BYTES = 208


def expected_output(
    values: Sequence[int] | None,
    capacity: int | None = None,
    output_is_null: bool = False,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> tuple[int, bytes]:
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or capacity is not None and (type(capacity) is not int or capacity < 0)
            or input_length is not None and (type(input_length) is not int or not 0 <= input_length <= MAX_INPUT)
            or input_is_null and values not in (None, [], ())
            or not input_is_null and values is not None and input_length is not None and input_length != len(values)):
        return -1, b""
    if input_is_null or values is None or not isinstance(values, (list, tuple)):
        return -1, b""
    if len(values) < 3 or len(values) > MAX_INPUT or any(
        type(value) is not int or not -(1 << 63) <= value < (1 << 63) for value in values
    ):
        return -1, b""

    p, k, request_count = values[:3]
    if not 2 <= p <= 6 or not 1 <= k <= 3 or k > p or not 0 <= request_count <= 8:
        return -1, b""
    initial_at = 3 + p * p
    requests_at = initial_at + k
    if len(values) != requests_at + request_count:
        return -1, b""

    metric_values = values[3:initial_at]
    metric = [metric_values[row * p:(row + 1) * p] for row in range(p)]
    if any(not 0 <= metric[i][j] <= 1000 for i in range(p) for j in range(p)):
        return -1, b""
    for i in range(p):
        for j in range(p):
            if ((i == j and metric[i][j] != 0)
                    or (i != j and metric[i][j] == 0)
                    or metric[i][j] != metric[j][i]):
                return -1, b""
            if any(metric[i][j] > metric[i][z] + metric[z][j] for z in range(p)):
                return -1, b""

    initial = tuple(sorted(values[initial_at:requests_at]))
    requests = tuple(values[requests_at:])
    if len(set(initial)) != k or any(not 0 <= point < p for point in initial):
        return -1, b""
    if any(not 0 <= request < p for request in requests):
        return -1, b""

    configurations = tuple(itertools.combinations(range(p), k))

    def matching_cost(left: tuple[int, ...], right: tuple[int, ...]) -> int:
        return min(sum(metric[left[i]][right[perm[i]]] for i in range(k))
                   for perm in itertools.permutations(range(k)))

    distances = {
        (left, right): matching_cost(left, right)
        for left in configurations for right in configurations
    }
    work = {configuration: distances[(initial, configuration)] for configuration in configurations}
    current = initial
    trajectory = [request_count, k]
    for request in requests:
        next_work = {
            target: min(work[source] + distances[(source, target)]
                        for source in configurations if request in source)
            for target in configurations
        }
        if request in current:
            selected = current
        else:
            choices = []
            for slot in range(k):
                candidate = tuple(sorted(current[:slot] + (request,) + current[slot + 1:]))
                choices.append((work[candidate] + metric[current[slot]][request], slot, candidate))
            selected = min(choices)[2]
        trajectory.extend(selected)
        current = selected
        work = next_work

    payload = b"".join(struct.pack("<q", value) for value in trajectory)
    if output_is_null or capacity is not None and capacity < len(payload):
        return -2, b""
    return len(payload), payload
