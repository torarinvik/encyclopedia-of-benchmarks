"""Oracle for the pinned, reset-per-call chaos-machine state transition."""

from __future__ import annotations

import struct

MAX_SEEDS = 64
MAX_PULLS = 64
MAX_SEED = 1_000_000
MAX_INPUT_LENGTH = MAX_SEEDS + 2
MAX_OUTPUT_BYTES = MAX_PULLS * 4
I64_MIN, I64_MAX = -(2**63), 2**63 - 1
INITIAL_BUFFER = (0.33, 0.44, 0.55, 0.44, 0.33)


def expected_output(values: list[int]) -> tuple[int, bytes]:
    if (not isinstance(values, list) or len(values) < 2 or len(values) > MAX_INPUT_LENGTH
            or any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values)):
        return -1, b""
    seed_count = values[0]
    if not 0 <= seed_count <= MAX_SEEDS or len(values) != seed_count + 2:
        return -1, b""
    seeds = values[1:1 + seed_count]
    pull_count = values[-1]
    if (any(not 0 <= seed <= MAX_SEED for seed in seeds)
            or not 0 <= pull_count <= MAX_PULLS):
        return -1, b""

    buffer_space = list(INITIAL_BUFFER)
    params_space = [0.0] * 5
    machine_time = 0
    for seed in seeds:
        for key in range(5):
            if buffer_space[key] == 0.0:
                return -1, b""
            evolution = float(seed / buffer_space[key])
            value = (buffer_space[(key + 1) % 5] + evolution) % 1.0
            rate = (params_space[key] + evolution) % 1.0 + 3.0
            buffer_space[key] = round(float(rate * value * (1.0 - value)), 10)
            params_space[key] = rate
        if not max(buffer_space) < 1.0 or not max(params_space) < 4.0:
            return -1, b""
        machine_time += 1

    output = bytearray()
    for _ in range(pull_count):
        key = machine_time % 5
        for _ in range(3):
            rate = params_space[key]
            value = buffer_space[key]
            buffer_space[key] = round(float(rate * value * (1.0 - value)), 10)
            params_space[key] = (machine_time * 0.01 + rate * 1.01) % 1.0 + 3.0
        x = int(buffer_space[(key + 2) % 5] * 10**10)
        y = int(buffer_space[(key - 2) % 5] * 10**10)
        x ^= y >> 13
        y ^= x << 17
        x ^= y >> 5
        output.extend(struct.pack("<I", x & 0xFFFFFFFF))
        machine_time += 1
    return pull_count * 4, bytes(output)
