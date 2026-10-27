"""Independent recursive-packing verifier for the bounded migration step."""

from __future__ import annotations

import struct
from collections.abc import Sequence

MAX_INPUT = 20


def _read(values: Sequence[int] | None):
    if (not isinstance(values, (list, tuple)) or len(values) < 6 or len(values) > MAX_INPUT
            or any(type(x) is not int or not -(1 << 63) <= x < (1 << 63) for x in values)):
        return None
    m, n, claimed, new_size = values[:4]
    if m not in (2, 3) or n not in range(1, 9) or claimed < 1 or new_size not in range(1, 21):
        return None
    if len(values) != 4 + 2 * n:
        return None
    jobs, bins = [], []
    for j in range(n):
        size, bin_id = values[4 + 2 * j:6 + 2 * j]
        if size not in range(1, 21) or bin_id not in range(m):
            return None
        jobs.append(size)
        bins.append(bin_id)
    return m, n, claimed, new_size, jobs, bins


def _partition_opt(m: int, jobs: list[int]) -> int:
    best = sum(jobs)
    loads = [0] * m

    def visit(index: int) -> None:
        nonlocal best
        if index == len(jobs):
            best = min(best, max(loads))
            return
        for machine in range(m):
            loads[machine] += jobs[index]
            visit(index + 1)
            loads[machine] -= jobs[index]

    visit(0)
    return best


def _apply(parsed):
    m, n, claim, new_size, jobs, bins = parsed
    optimum = _partition_opt(m, jobs + [new_size])
    if optimum != claim:
        return None
    final_bins = bins + [-1]
    loads = [0] * m
    for size, machine in zip(jobs, bins):
        loads[machine] += size
    relocated = 0
    if new_size * 2 <= optimum:
        chosen = min(range(m), key=lambda machine: (loads[machine], machine))
        final_bins[n] = chosen
        loads[chosen] += new_size
    else:
        chosen = None
        for machine in range(m):
            group = [j for j in range(n) if bins[j] == machine]
            if all(jobs[j] * 2 <= optimum for j in group) and sum(jobs[j] for j in group) >= new_size:
                chosen = machine
                break
        if chosen is None:
            return None
        extracted = []
        volume = 0
        for j in range(n):
            if bins[j] == chosen:
                extracted.append(j)
                volume += jobs[j]
                if volume >= new_size:
                    break
        if volume < new_size:
            return None
        final_bins[n] = chosen
        loads[chosen] = loads[chosen] + new_size - volume
        for j in extracted:
            target = min(range(m), key=lambda machine: (loads[machine], machine))
            final_bins[j] = target
            loads[target] += jobs[j]
            if target != chosen:
                relocated += jobs[j]
    return [optimum, relocated, *final_bins]


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or capacity is not None and (type(capacity) is not int or capacity < 0)
            or input_length is not None and (type(input_length) is not int
                                             or not 0 <= input_length <= MAX_INPUT)
            or input_is_null and values not in (None, [], ())
            or not input_is_null and values is not None and input_length is not None
            and input_length != len(values)):
        return -1, b""
    if input_is_null or values is None:
        return -1, b""
    parsed = _read(values)
    if parsed is None:
        return -1, b""
    fields = _apply(parsed)
    if fields is None:
        return -1, b""
    payload = b"".join(struct.pack("<q", value) for value in fields)
    if output_is_null or capacity is not None and capacity < len(payload):
        return -2, b""
    return len(payload), payload
