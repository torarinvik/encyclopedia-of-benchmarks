"""Independent deterministic oracle for the MATLAB particle swarm example."""

from __future__ import annotations

import struct

PARTICLE_COUNT = 50
DIMENSION_COUNT = 5
ITERATION_COUNT = 1000
MAX_INPUT_LENGTH = 2  # one seed plus one extra value for malformed-length coverage
MAX_SEED = (1 << 63) - 1
OUTPUT_VALUE_COUNT = 1 + DIMENSION_COUNT + ITERATION_COUNT
MAX_OUTPUT_BYTES = OUTPUT_VALUE_COUNT * 8
INVALID_RESULT = -1
INSUFFICIENT_CAPACITY_RESULT = -2


def solve(seed: int) -> list[float]:
    """Run the source recurrence with a portable xorshift64 stream."""
    state = seed

    def next_uniform() -> float:
        nonlocal state
        state ^= (state << 13) & 0xFFFFFFFFFFFFFFFF
        state ^= state >> 7
        state ^= (state << 17) & 0xFFFFFFFFFFFFFFFF
        state &= 0xFFFFFFFFFFFFFFFF
        return (state >> 11) * (1.0 / 9007199254740992.0)

    position = [
        [-10.0 + 20.0 * next_uniform() for _ in range(DIMENSION_COUNT)]
        for _ in range(PARTICLE_COUNT)
    ]
    velocity = [[0.0] * DIMENSION_COUNT for _ in range(PARTICLE_COUNT)]
    personal_position = [row.copy() for row in position]

    def sphere(point: list[float]) -> float:
        cost = 0.0
        for coordinate in point:
            cost += coordinate * coordinate
        return cost

    personal_cost = [sphere(row) for row in position]
    global_cost = float("inf")
    global_position = [0.0] * DIMENSION_COUNT
    for particle in range(PARTICLE_COUNT):
        if personal_cost[particle] < global_cost:
            global_cost = personal_cost[particle]
            global_position = personal_position[particle].copy()

    best_cost_history: list[float] = []
    inertia = 1.0
    for _ in range(ITERATION_COUNT):
        for particle in range(PARTICLE_COUNT):
            personal_random = [next_uniform() for _ in range(DIMENSION_COUNT)]
            social_random = [next_uniform() for _ in range(DIMENSION_COUNT)]
            for coordinate in range(DIMENSION_COUNT):
                cognitive = (2.0 * personal_random[coordinate]) * (
                    personal_position[particle][coordinate] - position[particle][coordinate]
                )
                social = (2.0 * social_random[coordinate]) * (
                    global_position[coordinate] - position[particle][coordinate]
                )
                velocity[particle][coordinate] = (
                    inertia * velocity[particle][coordinate] + cognitive + social
                )
                position[particle][coordinate] += velocity[particle][coordinate]

            cost = sphere(position[particle])
            if cost < personal_cost[particle]:
                personal_position[particle] = position[particle].copy()
                personal_cost[particle] = cost
                if personal_cost[particle] < global_cost:
                    global_position = personal_position[particle].copy()
                    global_cost = personal_cost[particle]

        best_cost_history.append(global_cost)
        inertia *= 0.99

    return [global_cost, *global_position, *best_cost_history]


def expected_output(input_values: list[int]) -> tuple[int, bytes]:
    """Return (output byte count, packed vector), or (-1, empty) if invalid."""
    if (not isinstance(input_values, list) or len(input_values) != 1
            or type(input_values[0]) is not int or not 1 <= input_values[0] <= MAX_SEED):
        return INVALID_RESULT, b""
    vector = solve(input_values[0])
    return MAX_OUTPUT_BYTES, b"".join(struct.pack("<d", value) for value in vector)
