"""Oracle for the deterministic duplicate-XOR workload in BenchmarkGame/puzzle."""

from __future__ import annotations

import struct

MAX_ARRAY_SIZE = 100_000
MAX_ROUNDS = 8
MAX_SCANS_PER_ARRAY = 64
MAX_INPUT_LENGTH = 4  # one trailing word is parseable so the oracle can reject it
MAX_OUTPUT_BYTES = MAX_ROUNDS * 4
_U64_MASK = (1 << 64) - 1


def _next_random(state: int) -> tuple[int, int]:
    """Match puzzle.c's local rand(): u64 LCG, then a truncated u32 quotient."""
    state = (state * 1_103_515_245 + 12_345) & _U64_MASK
    value = (((state >> 16) & 0xFFFF_FFFF) % 32_767) + 1
    return state, value


def expected_output(
    values: list[int],
    output_capacity: int | None = None,
    output_is_null: bool = False,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> tuple[int, bytes]:
    if input_is_null:
        return -1, b""
    if (not isinstance(values, list) or len(values) != 3
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return -1, b""
    if input_length is not None and input_length != 3:
        return -1, b""

    array_size, rounds, scans_per_array = values
    if (not 1 <= array_size <= MAX_ARRAY_SIZE
            or not 1 <= rounds <= MAX_ROUNDS
            or not 1 <= scans_per_array <= MAX_SCANS_PER_ARRAY):
        return -1, b""

    required_bytes = rounds * 4
    if output_capacity is None:
        output_capacity = required_bytes
    if (type(output_capacity) is not int or output_capacity < required_bytes
            or output_is_null):
        return -2, b""

    state = 1  # puzzle.c calls srand(1) once, before all outer iterations
    results: list[int] = []
    for _ in range(rounds):
        state, draw = _next_random(state)
        duplicate = array_size * draw // 32_768 + 1
        data = list(range(array_size + 1))
        data[0] = duplicate
        for index in range(array_size, 0, -1):
            state, draw = _next_random(state)
            chosen = (index + 1) * draw // 32_768
            if chosen == index + 1:  # present in the upstream source; unreachable here
                chosen -= 1
            data[index], data[chosen] = data[chosen], data[index]

        # The source repeats this read-only XOR scan scans_per_array times; each
        # pass has the same result, so one pass is sufficient for the oracle.
        found = 0
        for index, item in enumerate(data):
            found ^= (index + 1) ^ item
        found ^= len(data)
        results.append(found)

    return required_bytes, struct.pack("<" + "i" * rounds, *results)
